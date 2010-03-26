require 'datafile'
require 'template/premis'
require 'net/http'
require 'cgi'
require 'metadata'

class DataFile

  def describe! options={}
    doc = ask_description_service(:location => "file:#{File.expand_path datapath }",
                                  :uri => uri,
                                  :originalName => metadata['sip-path'] || metadata['aip-path'] )
    fix_event_ids doc
    metadata['describe-file-object'] = element_doc_as_str doc, "//P:object[@xsi:type='file']"
    metadata['describe-event'] = element_doc_as_str doc, "//P:event"
    metadata['describe-agent'] = element_doc_as_str doc, "//P:agent"
    metadata['describe-bitstream-objects'] = elements_doc_as_str doc, "//P:object[@xsi:type='bitstream']"

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

  def fix_event_ids doc
    event_uri = "#{uri}/event/describe/#{next_event_index 'format description'}"
    doc.find_first("P:object/P:linkingEventIdentifier/P:linkingEventIdentifierValue", NS_PREFIX).content = event_uri
    doc.find_first("P:event/P:eventIdentifier/P:eventIdentifierValue", NS_PREFIX).content = event_uri
  end

  def describe_derivation src_uri, derivation_method, agent_uri

      event_uri = "#{uri}/event/#{derivation_method}/#{next_event_index derivation_method}"
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
    url = URI.parse "#{Daitss::CONFIG['description-url']}?#{query_str}"
    req = Net::HTTP::Get.new url.path
    req.form_data = query unless query.empty?

    res = Net::HTTP.start(url.host, url.port) do |http|
      http.read_timeout = Daitss::CONFIG['http-timeout']
      http.request req
    end

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

  def elements_doc_as_str doc, xpath
    ns = doc.find xpath, NS_PREFIX

    ns.inject("") do |acc, n|
      d = XML::Document.new
      d.root = d.import n
      acc << d.root.to_s
    end

  end

end
