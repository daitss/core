require 'daitss/proc/datafile'
require 'daitss/proc/template/premis'
require 'net/http'
require 'cgi'
require 'uri'
require 'daitss/proc/metadata'
require 'daitss/xmlns'

module Daitss

  class DataFile

    def describe!
      doc = ask_description_service(:uri => uri,
                                    :originalName => metadata['aip-path'])
      augment_fixity doc if @wip.file_group
      fix_event_ids doc
      fix_jhove_ids doc
      metadata['describe-file-object'] = element_doc_as_str doc, "//P:object[@xsi:type='file']"
      metadata['describe-event'] = element_doc_as_str doc, "//P:event"
      metadata['describe-agent'] = element_doc_as_str doc, "//P:agent"
      metadata['describe-bitstream-objects'] = elements_doc_as_str doc, "//P:object[@xsi:type='bitstream']"

      if metadata['transformation-source']
        src_uri = metadata['transformation-source']
        strategy = metadata['transformation-strategy']
        describe_derivation src_uri, strategy if strategy
      end

    end

    def file_object
      metadata['describe-file-object']
    end

    def bitstream_objects

      if metadata.has_key? 'describe-bitstream-objects'
        doc = XML::Document.string "<root>#{metadata['describe-bitstream-objects']}</root>"
        doc.root.children.select { |c| c.element? }.map &:to_s
      else
        []
      end

    end

    private

    def augment_fixity doc
      href = metadata['sip-path'] ? URI.escape(metadata['sip-path']) : nil
      file_node = @wip.file_group.find_first %Q{M:file[M:FLocat/@xlink:href = "#{href}"]}, NS_PREFIX
      # XXX sip checksums could be done better in submit
      if file_node and file_node['CHECKSUM'] and file_node['CHECKSUMTYPE'] and %w(SHA-1 MD5).include?(file_node['CHECKSUMTYPE'])
        fixity_origin = doc.find_first %Q{
        //P:objectCharacteristics /
          P:fixity[ P:messageDigestAlgorithm = '#{ file_node['CHECKSUMTYPE'] }' ] /
            P:messageDigestOriginator
        }, NS_PREFIX

        fixity_origin.content = 'Depositor'
      end

    end

    def fix_jhove_ids doc

      doc.find("//aes:*/@ID", NS_PREFIX).each do |id_attr|

        doc.find("//aes:*/@*[. = '#{id_attr.value}']", NS_PREFIX).each do |attr|
          attr.value = "#{attr.value}.#{self.id}"
        end

      end

    end

    def fix_event_ids doc
      event_uri = "#{uri}/event/describe/#{next_event_index 'format description'}"
      doc.find_first("P:object/P:linkingEventIdentifier/P:linkingEventIdentifierValue", NS_PREFIX).content = event_uri
      doc.find_first("P:event/P:eventIdentifier/P:eventIdentifierValue", NS_PREFIX).content = event_uri
    end

    def describe_derivation src_uri, strategy
      event_doc = XML::Document.string metadata["#{strategy}-event"]
      event_uri = event_doc.find_first("//P:eventIdentifierValue", NS_PREFIX).content

      rel_doc = XML::Document::string relationship(:type => 'derivation',
                                                   :sub_type => 'has source',
                                                   :related_objects => [src_uri],
                                                   :related_events => [event_uri])

      # update the description
      doc = XML::Document::string metadata['describe-file-object']
      rel = doc.import rel_doc.root
      object = doc.find_first "/P:object[@xsi:type='file']", NS_PREFIX
      insertion_point = object.find_first %Q{
      P:linkingEventIdentifier |
      P:linkingIntellectualEntityIdentifier |
      P:linkingRightsStatementIdentifier
      }, NS_PREFIX

      if insertion_point
        insertion_point.prev = rel
      else
        object << rel
      end

      metadata['describe-file-object'] = doc.root.to_s
    end

    def ask_description_service query={}
      begin
        query_str = query.map { |key, value| "#{key.id2name}=#{CGI::escape value.to_s}" }.join '&'
        url_location =  archive.describe_url + '/describe'
        url = URI.parse url_location
        # ask for the main doc with the link, event, agent
        if (archive.remote_describe)
          c = Curl::Easy.new "#{url_location}?#{query_str}"
          c.timeout = Archive.instance.http_timeout
          c.multipart_form_post = true
          data = Curl::PostField.file 'file', data_file
          c.http_post data
          c.response_code == 200 or c.error("bad status")   
          doc = XML::Document.string c.body_str     
        else
          path = File.expand_path data_file
          c = Curl::Easy.new "#{url_location}?location=file:#{File.expand_path data_file}&#{query_str}"
          c.timeout = Archive.instance.http_timeout
          c.perform
          c.response_code == 200 or c.error("bad status")   
          doc = XML::Document.string c.body_str
        end
      rescue => e
        raise e
      rescue Interrupt
        exit 1
      end
    end

    def element_doc_as_str doc, xpath
      n = doc.find_first xpath, NS_PREFIX

      if n
        d = XML::Document.new
        d.root = d.import n
        d.root.to_s
      end

    end

    def elements_doc_as_str doc, xpath
      ns = doc.find xpath, NS_PREFIX

      ns.inject("") do |acc, n|
        d = XML::Document.new
        d.root = d.import n
        acc << d.root.to_s
      end

    end

  end

end
