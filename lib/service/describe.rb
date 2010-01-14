require 'datafile'
require 'net/http'
require 'cgi'

class DataFile

  def describe! 
    doc = ask_description_service(:location => URI.join('file:/', File.expand_path(datapath)),
                                  :uri => uri, 
                                  :originalName => metadata['sip-path'])
    metadata['describe-file-object'] = element_doc_as_str doc, "//P:object[@xsi:type='file']" 
    metadata['describe-event'] = element_doc_as_str doc, "//P:event"
    metadata['describe-agent'] = element_doc_as_str doc, "//P:agent" 
    metadata['describe-bitstream-objects'] = element_doc_as_str doc, "//P:object[@xsi:type='bitstream']"
    @wip.tags["describe-#{id}"] = Time.now.xmlschema
  end

  private

  def ask_description_service query={}
    query_str = query.map { |key, value| "#{key.id2name}=#{CGI::escape value.to_s}" }.join '&'
    url = URI.join CONFIG['description-url'], "?#{query_str}"
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
