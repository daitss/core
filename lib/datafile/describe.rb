require 'datafile'
require 'template/premis'
require 'net/http'
require 'cgi'

class DataFile

  def describe! options={}
    doc = ask_description_service(:location => "file:#{File.expand_path datapath }",
                                  :uri => uri, 
                                  :originalName => metadata['sip-path'])
    metadata['describe-file-object'] = element_doc_as_str doc, "//P:object[@xsi:type='file']" 
    metadata['describe-event'] = element_doc_as_str doc, "//P:event"
    metadata['describe-agent'] = element_doc_as_str doc, "//P:agent" 
    metadata['describe-bitstream-objects'] = element_doc_as_str doc, "//P:object[@xsi:type='bitstream']"

    if options[:derivation_source] and options[:derivation_method]
      event_uri = "#{options[:derivation_source]}/event/#{options[:derivation_method]}"
      metadata["#{options[:derivation_method]}-event"] = event :id => event_uri, :type => options[:derivation_method]

      rel_doc = XML::Document::string relationship(:type => 'derivation',
                                                   :sub_type => 'has source',
                                                   :related_objects => [ options[:derivation_source] ],
                                                   :related_events => [event_uri])
      #
      # update the description
      doc = XML::Document::string metadata['describe-file-object']
      rel = doc.import rel_doc.root
      object = doc.find_first "/P:object[@xsi:type='file']", NS_PREFIX
      insertion_point = object.find_first "P:linkingEventIdentifier | P:linkingIntellectualEntityIdentifier | P:linkingRightsStatementIdentifier", NS_PREFIX

      if insertion_point
        insertion_point.prev = rel
      else
        object << rel
      end

      metadata['describe-file-object'] = doc.to_s

    end

  end

  private

  def ask_description_service query={}
    query_str = query.map { |key, value| "#{key.id2name}=#{CGI::escape value.to_s}" }.join '&'
    url = URI.parse "#{CONFIG['description-url']}?#{query_str}"
      res = Net::HTTP.get_response url

    case res
    when Net::HTTPSuccess then XML::Document.string res.body
    else res.error!
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

end
