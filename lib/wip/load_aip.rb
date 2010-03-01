require 'wip'
require 'digest/sha1'

class Wip

  def load_from_aip
    load_aip_record
    load_copy
    load_datafiles
    load_representations
    load_old_package_digiprov
    load_old_datafile_digiprov
    load_normalized_versions
  end

  def load_aip_record
    aip = Aip.get! self.id
    metadata['aip-descriptor'] = aip.xml
    metadata['copy-url'] = aip.copy_url
    metadata['copy-sha1'] = aip.copy_sha1
    metadata['copy-size'] = aip.copy_size
  end

  def load_copy
    url = ::URI.parse metadata['copy-url']
    req = Net::HTTP::Get.new url.path

    res = Net::HTTP.start(url.host, url.port) do |http| 
      http.read_timeout = Daitss::CONFIG['http-timeout']
      http.request(req)
    end

    res.error! unless Net::HTTPSuccess === res

    size = res.body.size
    unless metadata['copy-size'].to_i == size
      raise "#{url} size is wrong: expected #{metadata['copy-size']}, actual #{size}" 
    end

    sha1 = Digest::SHA1.hexdigest res.body
    unless metadata['copy-sha1'] == sha1
      raise "#{url} sha1 is wrong: expected #{metadata['copy-sha1']}, actual #{sha1}" 
    end

    metadata['copy-data'] = res.body
  end

  def load_datafiles
    doc = XML::Document.string metadata['aip-descriptor']

    Tempdir.new do |tdir|

      aip_dir = self.id
      tarball_file = "#{aip_dir}.tar"

      Dir::chdir(tdir.path) do
        open(tarball_file, 'w') { |io| io.write metadata['copy-data'] }
        %x{tar xf #{tarball_file}}
        raise "could not extract tarball: #{$?}" unless $?.exitstatus == 0
      end

      df_paths = doc.find("//M:file", NS_PREFIX).map do |file_node|

        # make  a new datafile
        df_id = file_node['ID'].slice /file-(\d+)/, 1
        df = new_datafile df_id

        # extract the data
        aip_path = file_node.find_first('M:FLocat/@xlink:href', NS_PREFIX).value
        tar_file = File.join tdir.path, aip_dir, aip_path
        FileUtils::cp tar_file, df.datapath

        expected_size = file_node['SIZE'].to_i
        actual_size = df.size 
        unless df.size == expected_size
          raise "datafile #{df.id} size is wrong: expected #{expected_size}, actual #{actual_size}" 
        end

        expected_sha1 = file_node['CHECKSUM']
        actual_sha1 = df.open { |io| Digest::SHA1.hexdigest io.read } 
        unless expected_sha1 == actual_sha1
          raise "datafile #{df.id} sha1 is wrong: expected #{expected_sha1}, actual #{actual_sha1}" 
        end

        df['aip-path'] = aip_path


      end

    end

  end

  def load_representations
    doc = XML::Document.string metadata['aip-descriptor']

    %w(original current normalized).each do |rep|
      xpath = "/M:mets/M:structMap[@ID='#{rep}']//M:fptr"

      dfs = doc.find(xpath, NS_PREFIX).map do |fptr_node|
        df_id = fptr_node['FILEID'].slice /file-(\d+)/, 1
        datafiles.find { |df| df.id == df_id }
      end

      self.send "#{rep}_rep=".to_sym, dfs
    end

  end

  def load_old_package_digiprov
    doc = XML::Document.string metadata['aip-descriptor']
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

  def load_old_datafile_digiprov

    datafiles.each do |df|
      doc = XML::Document.string metadata['aip-descriptor']

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

  def load_normalized_versions

    [datafiles.first].each do |df|
      doc = XML::Document.string metadata['aip-descriptor']

      xpath = %Q{
        //P:event[P:eventType = 'normalize']
                 [P:linkingObjectIdentifier[P:linkingObjectRole = 'source']
                                           [P:linkingObjectIdentifierValue = '#{df.uri}']]
                 /P:linkingObjectIdentifier[P:linkingObjectRole = 'outcome']/P:linkingObjectIdentifierValue
      }

      normalization_outcome_node = doc.find_first xpath, NS_PREFIX

      if normalization_outcome_node
        outcome_uri = normalization_outcome_node.content
        norm_df = datafiles.find { |x| x.uri == outcome_uri }

        if norm_df
          df.normalized_version = norm_df
        end

      end

    end

  end

end

