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

    if options[:derivation_source]

      src_uri = options[:derivation_source]

      derivation_method = case options[:derivation_method]
                          when :normalize then 'normalize'
                          when :migrate then 'migrate'
                          else raise "derivation method is missing!"
                          end

      raise "derivation agent is missing" unless options[:derivation_agent]

      describe_derivation src_uri, derivation_method, options[:derivation_agent]
    end

  end

  private

  def describe_derivation src_uri, derivation_method, agent_uri

      event_uri = "#{uri}/event/#{derivation_method}"
      metadata["#{derivation_method}-event"] = event(:id => event_uri,
                                                     :type => derivation_method,
                                                     :linking_agents => [ agent_uri ],
                                                     :linking_objects => [ 
                                                       {:uri => src_uri, :role => 'source'}, 
                                                       {:uri => uri, :role => 'outcome'}
                                                     ])

      metadata["#{derivation_method}-agent"] = agent(:id => agent_uri,
                                                     :name => 'daitss transformation service', 
                                                     :type => 'software')


      rel_doc = XML::Document::string relationship(:type => 'derivation',
                                                   :sub_type => 'has source',
                                                   :related_objects => [src_uri],
                                                   :related_events => [event_uri])

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

      metadata['describe-file-object'] = doc.root.to_s
  end

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
