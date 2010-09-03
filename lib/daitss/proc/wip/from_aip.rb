require 'daitss/proc/wip'
require 'daitss/proc/aip_archive'
require 'daitss/proc/datafile/obsolete'
require 'digest/sha1'

class Wip

  def load_from_aip

    # need tb
    load_datafiles

    # need descriptor
    load_dmd
    load_sip_descriptor
    load_datafile_transformation_sources
    load_old_package_digiprov
    load_old_datafile_digiprov
  end

  # SMELL this can go into a deterministic dmd section in the aip descriptor and be recycled
  # it wont change over time
  def load_dmd
    doc = XML::Document.string self.package.aip.xml

    # title
    title_node = doc.find_first "//mods:mods/mods:titleInfo/mods:title", NS_PREFIX

    if title_node
      metadata['dmd-title'] = title_node.content
    end

    # volume
    volume_node = doc.find_first(%Q{
      //mods:mods/mods:part/mods:detail[@type = 'volume']/mods:number
    }, NS_PREFIX)

    if volume_node
      metadata['dmd-volume'] = volume_node.content
    end

    # issue
    issue_node = doc.find_first(%Q{
      //mods:mods/mods:part/mods:detail[@type = 'issue']/mods:number
    }, NS_PREFIX)

    if issue_node
      metadata['dmd-issue'] = issue_node.content
    end

    # entity id
    entity_id_node = doc.find_first(%Q{
      //mods:mods/mods:identifier[@type = 'entity id']
    }, NS_PREFIX)

    if entity_id_node
      metadata['dmd-entity-id'] = entity_id_node.content
    end

  end

  # transfer datafiles into the wip
  def load_datafiles
    doc = XML::Document.string self.package.aip.xml

    tdir = Dir.mktmpdir

    aip_dir = self.id
    tarball_file = "#{aip_dir}.tar"

    Dir.chdir tdir do
      data = self.package.aip.copy.get_from_silo
      open(tarball_file, 'w') { |io| io.write data }
      %x{tar xf #{tarball_file}}
      raise "could not extract tarball: #{$?}" unless $?.exitstatus == 0
    end

    df_paths = doc.find("//M:file", NS_PREFIX).map do |file_node|

      # make  a new datafile
      df_id = file_node['ID'].slice /^file-(.+)$/, 1

      df = case df_id
           when /^\d+$/ then new_original_datafile df_id
           when /^\d+-mig-\d+$/ then new_migrated_datafile df_id
           when /^\d+-norm-\d+$/ then new_normalized_datafile df_id
           end

      # extract the data
      if file_node.children.any? { |n| n.element? and n.name == 'FLocat' }

        # copy over the file
        aip_path = file_node.find_first('M:FLocat/@xlink:href', NS_PREFIX).value
        tar_file = File.join tdir, aip_dir, aip_path
        FileUtils::cp tar_file, df.datapath

        # check the size
        expected_size = file_node['SIZE'].to_i
        actual_size = df.size

        unless df.size == expected_size
          raise "datafile #{df.id} size is wrong: expected #{expected_size}, actual #{actual_size}"
        end

        # check the sha1
        expected_sha1 = file_node['CHECKSUM']
        actual_sha1 = df.open { |io| Digest::SHA1.hexdigest io.read }

        unless expected_sha1 == actual_sha1
          raise "datafile #{df.id} sha1 is wrong: expected #{expected_sha1}, actual #{actual_sha1}"
        end

        df['aip-path'] = aip_path
      end

      # load the premis objects
      uri = file_node['OWNERID']
      object_node = doc.find_first(%Q{
            //P:object [@xsi:type='file']
                       [P:objectIdentifier/P:objectIdentifierValue = '#{uri}']
      }, NS_PREFIX)
      df['describe-file-object'] = object_node.to_s if object_node

      bs_uris = object_node.find(%Q{
          P:relationship
            [ P:relationshipType = 'structural' ]
            [ P:relationshipSubType = 'includes' ] /
              P:relatedObjectIdentification /
                P:relatedObjectIdentifierValue
      }, NS_PREFIX).map { |node| node.content }

      bs_nodes = bs_uris.map do |bs_uri|
        doc.find(%Q{
              //P:object [@xsi:type='bitstream']
                         [P:objectIdentifier/P:objectIdentifierValue = '#{bs_uri}']
        }, NS_PREFIX)
      end

      df['describe-bitstream-objects'] = bs_nodes.join
    end

    # load xml res tarballs
    unless File.directory? old_xml_res_tarball_dir
      FileUtils.mkdir old_xml_res_tarball_dir
    end

    pattern = File.join tdir, aip_dir, "#{XML_RES_TARBALL_BASENAME}-*.tar"

    Dir[pattern].each do |f|
      FileUtils.cp f, File.join(old_xml_res_tarball_dir, File.basename(f))
    end

    FileUtils.rm_r tdir
  end

  OLD_XML_RES_DIR = 'xmlresolutions'
  def old_xml_res_tarball_dir
    File.join(path, OLD_XML_RES_DIR)
  end

  def old_xml_res_tarballs
    pattern = File.join old_xml_res_tarball_dir, '*'
    Dir[pattern]
  end

  # transfer sip descriptor
  def load_sip_descriptor
    name = File.join AipArchive::SIP_FILES_DIR, "#{self.package.sip.name}.xml"
    sd_df = original_datafiles.find { |df| name == df['aip-path'] }
    metadata['sip-descriptor'] = File.read sd_df.datapath
  end

  # transfer source uris to transformation products from the events
  def load_datafile_transformation_sources
    doc = XML::Document.string self.package.aip.xml

    {
      'migrate' => migrated_datafiles,
      'normalize' => normalized_datafiles
    }.each do |name, dfs|

      dfs.each do |df|
        source_uri = doc.find_first(%Q{
        // P:event [ P:eventType = '#{ name }' ]
                   [
                     P:linkingObjectIdentifier [ P:linkingObjectRole = 'outcome']
                                               [ P:linkingObjectIdentifierValue = '#{ df.uri }' ]
                   ]/
          P:linkingObjectIdentifier [ P:linkingObjectRole = 'source' ] /
            P:linkingObjectIdentifierValue
        }, NS_PREFIX).content

        df['transformation-source'] = source_uri
      end

    end

  end

  # transfer package wide events and agents
  def load_old_package_digiprov
    doc = XML::Document.string self.package.aip.xml
    es = doc.find("//P:event[P:linkingObjectIdentifier/P:linkingObjectIdentifierValue = '#{uri}']", NS_PREFIX)
    metadata['old-digiprov-events'] = es.map { |e| e.to_s }.join "\n"

    as = es.map do |event|

      xpath = "P:linkingAgentIdentifier/P:linkingAgentIdentifierValue"
      agent_ids = event.find(xpath, NS_PREFIX).map { |agent_id| agent_id.content }

      agent_ids.map do |agent_id|
        xpath = "//P:agent[P:agentIdentifier/P:agentIdentifierValue = '#{agent_id}']"
        doc.find_first(xpath, NS_PREFIX)
      end

    end

    metadata['old-digiprov-agents'] = as.flatten.map { |a| a.to_s }.join "\n"
  end

  # transfer events and the respective agents for each datafile
  def load_old_datafile_digiprov
    doc = XML::Document.string self.package.aip.xml

    all_datafiles.each do |df|

      # transfer old events
      xpath = %Q{
        //P:event
            [P:eventType != 'normalize' and P:eventType != 'migrate' ]
            [P:linkingObjectIdentifier/P:linkingObjectIdentifierValue = '#{df.uri}']
      }
      es_desc = doc.find(xpath, NS_PREFIX)

      xpath = %Q{
        //P:event
            [P:eventType = 'normalize' or P:eventType = 'migrate']
            [P:linkingObjectIdentifier
                [P:linkingObjectIdentifierValue = '#{df.uri}']
                [P:linkingObjectRole = 'outcome']]
      }
      es_xform = doc.find(xpath, NS_PREFIX)

      es = es_desc.to_a + es_xform.to_a
      df['old-digiprov-events'] = es.map { |e| e.to_s }.join "\n"

      # transfer old agents used in the events
      as = es.map do |event|
        xpath = "P:linkingAgentIdentifier/P:linkingAgentIdentifierValue"
        agent_ids = event.find(xpath, NS_PREFIX).map { |agent_id| agent_id.content }

        agent_ids.map do |agent_id|
          xpath = "//P:agent[P:agentIdentifier/P:agentIdentifierValue = '#{agent_id}']"
          doc.find_first(xpath, NS_PREFIX)
        end

      end

      df['old-digiprov-agents'] = as.flatten.map { |a| a.to_s }.join "\n"
    end

  end

end
