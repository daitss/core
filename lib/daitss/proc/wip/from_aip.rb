require 'daitss/proc/wip'
require 'daitss/proc/wip/tarball'
require 'daitss/proc/datafile/obsolete'
require 'digest/sha1'
require 'uri'
require 'ruby-debug'
module Daitss

  class Wip

    def load_from_aip

      # need tb
      step('load aip datafiles') { load_datafiles }

      # need descriptor
      step('load aip metadata') do
        load_dmd
        load_sip_descriptor
        load_datafile_transformation_sources
        load_old_package_digiprov
        load_old_datafile_digiprov
      end

    end

    # SMELL this can go into a deterministic dmd section in the aip descriptor and be recycled
    # it wont change over time
    def load_dmd
      metadata["dmd-account"] = self.package.project.account.id
      metadata["dmd-project"] = self.package.project.id

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
      @premisNS = "P"
      doc = XML::Document.string self.package.aip.xml
      # check if the aip descriptor is using premis-v2 namespace prefix
      attrs =  doc.root.attributes
      attrs.each do |name|
        if name.to_s.include? "info:lc/xmlns/premis-v2"
          @premisNS = "PV2"
        end
      end

      tdir = Dir.mktmpdir nil, ENV['TMPDIR']

      aip_dir = self.id
      tarball_file = "#{aip_dir}.tar"

      Dir.chdir tdir do
        package.aip.copy.download tarball_file
        %x{tar xf #{tarball_file}}
        raise "could not extract tarball: #{$?}" unless $?.exitstatus == 0
      end

      df_paths = doc.find("//M:file", NS_PREFIX).map do |file_node|

        # make a new datafile
        df_id = file_node['ID'].slice /^file-(.+)$/, 1

        # SMELL this needs to be revised to disseminate a d1 package with the stupid DFIDs
        df = case df_id
             when /^(F.*|\d+)-mig-\d+$/ then new_migrated_datafile df_id
             when /^(F.*|\d+)-norm-\d+$/ then new_normalized_datafile df_id
             when /^(F.*|\d+)$/ then new_original_datafile df_id              
             else raise "unknown df id format #{df_id}"
             end

        # extract the data
        if file_node.children.any? { |n| n.element? and n.name == 'FLocat' }

          # copy over the file
          aip_path_href = file_node.find_first('M:FLocat/@xlink:href', NS_PREFIX).value
          aip_path = URI.unescape aip_path_href
          tar_file = File.join tdir, aip_dir, aip_path
          FileUtils::cp tar_file, df.data_file

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

          # the sip path cannot contains SIP_FILES_DIR, otherwise, the wip cannot detect which file is the sip descriptor.
          sip_path = aip_path.clone
          sip_path.slice!(Wip::SIP_FILES_DIR+'/')
          df['sip-path'] = sip_path
          df['aip-path'] = aip_path
        end

        # load the premis objects (v3 xpath)
        uri = file_node['OWNERID']
        ns = @premisNS
        object_node = doc.find_first(%Q{
            //#{ns}:object[@xsi:type='file']
                       [#{ns}:objectIdentifier/#{ns}:objectIdentifierValue = '#{uri}']
        }, NS_PREFIX)

        bs_uris = object_node.find(%Q{
          #{@premisNS}:relationship
            [ #{@premisNS}:relationshipType = 'structural' ]
            [ #{@premisNS}:relationshipSubType = 'includes' ] /
              #{@premisNS}:relatedObjectIdentifier /
                #{@premisNS}:relatedObjectIdentifierValue
        }, NS_PREFIX).map { |node| node.content }

        bs_nodes = bs_uris.map do |bs_uri|
          doc.find_first(%Q{
              //#{@premisNS}:object [@xsi:type='bitstream']
                         [#{@premisNS}:objectIdentifier/#{@premisNS}:objectIdentifierValue = '#{bs_uri}']
          }, NS_PREFIX)
        end

        df['describe-file-object'] = object_node.to_s if object_node

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

    ensure
      FileUtils.rm_r tdir if tdir
    end
    end
    # transfer sip descriptor
    def load_sip_descriptor
      name = File.join Wip::SIP_FILES_DIR, "#{self.package.sip.name}.xml"
      sd_df = original_datafiles.find { |df| name == df['aip-path'] }

      # look for the sip descriptor one directory lower if we can't find it at the top level
      if sd_df.nil?
        sd_df = original_datafiles.find do |df|
          parts = df['aip-path'].split File::SEPARATOR

          parts.size == 3 and
          parts[0] == Wip::SIP_FILES_DIR and
          parts[2] == "#{self.package.sip.name}.xml"
        end

      end

      raise "sip descriptor missing: #{name}" unless sd_df
      metadata['sip-descriptor'] = File.read sd_df.data_file
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
        // #{@premisNS}:event [ #{@premisNS}:eventType = '#{ name }' ]
                   [
                     #{@premisNS}:linkingObjectIdentifier [ #{@premisNS}:linkingObjectRole = 'outcome']
                                               [ #{@premisNS}:linkingObjectIdentifierValue = '#{ df.uri }' ]
                   ]/
          #{@premisNS}:linkingObjectIdentifier [ #{@premisNS}:linkingObjectRole = 'source' ] /
            #{@premisNS}:linkingObjectIdentifierValue
          }, NS_PREFIX)

          df['transformation-source'] = source_uri.content if source_uri
        end

      end

    end

    # transfer package wide events and agents
    def load_old_package_digiprov
      doc = XML::Document.string self.package.aip.xml

      es = doc.find("//#{@premisNS}:event[#{@premisNS}:linkingObjectIdentifier/#{@premisNS}:linkingObjectIdentifierValue = '#{uri}']", NS_PREFIX)

      metadata['old-digiprov-events'] = es.map { |e| e.to_s }.join "\n"

      as = es.map do |event|

        xpath = "#{@premisNS}:linkingAgentIdentifier/#{@premisNS}:linkingAgentIdentifierValue"
        agent_ids = event.find(xpath, NS_PREFIX).map { |agent_id| agent_id.content }

        agent_ids.map do |agent_id|
          xpath = "//#{@premisNS}:agent[#{@premisNS}:agentIdentifier/#{@premisNS}:agentIdentifierValue = '#{agent_id}']"
          doc.find_first(xpath, NS_PREFIX)
        end

      end

      metadata['old-digiprov-agents'] = as.flatten.map { |a| a.to_s }.join "\n"
    end

    # transfer events and the respective agents for each datafile
    def load_old_datafile_digiprov
       doc = XML::Document.string self.package.aip.xml

      # Buffer all agents into a local hash and look it up later
      # instead of looking it up everytime from the 'doc'
      xpath = "//#{@premisNS}:agent"
      agents_pool = doc.find(xpath, NS_PREFIX);

      agents_hash = Hash.new
      agents_pool.each do |agent|
            id_value = agent.find_first("#{@premisNS}:agentIdentifier/#{@premisNS}:agentIdentifierValue", NS_PREFIX).content
            agents_hash[id_value] = agent
      end

      all_datafiles.each do |df|

        # transfer old events
        xpath = %Q{
          //#{@premisNS}:event
          [#{@premisNS}:linkingObjectIdentifier/#{@premisNS}:linkingObjectIdentifierValue = '#{df.uri}']
        }

        es_obj = doc.find(xpath, NS_PREFIX)
        es = es_obj.to_a
        events_temp = Array.new

        # transfer old agents used in the events
        as = es.map do |event|

          # Filter out all events which do not match the criteria
          check1_xpath = "#{@premisNS}:eventType = 'normalize' or #{@premisNS}:eventType = 'migrate'"
          if true == event.find(check1_xpath, NS_PREFIX)
            check2_xpath = "#{@premisNS}:linkingObjectIdentifier
            [#{@premisNS}:linkingObjectIdentifierValue = '#{df.uri}']
            [#{@premisNS}:linkingObjectRole = 'outcome']"
            if event.find(check2_xpath, NS_PREFIX).size == 0
              next
            end
          end

          events_temp << event.to_s

          xpath = "#{@premisNS}:linkingAgentIdentifier/#{@premisNS}:linkingAgentIdentifierValue"
          agent_ids = event.find(xpath, NS_PREFIX).map { |agent_id| agent_id.content }

          agent_ids.map do |agent_id|
            # Look it up from Hash of agents
            agents_hash[agent_id]
          end

        end

        df['old-digiprov-events'] = events_temp.map { |e| e.to_s }.join "\n"
        df['old-digiprov-agents'] = as.flatten.map { |a| a.to_s }.join "\n"
       
      end

    end

  end

