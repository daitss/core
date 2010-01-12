require 'datafile'
require 'net/http'
require 'cgi'

class DataFile

  def described?
    @wip.tags.has_key? "describe-#{id}"
  end

  def describe! 

    query = {
      :location => URI.join('file:/', File.expand_path(datapath)).to_s,
      :uri => uri, 
      :originalName => metadata['sip-path']
    }

    query_str = query.map { |key, value| "#{key.id2name}=#{CGI::escape value}" }.join '&'
    url = URI.join CONFIG['description-url'], "?#{query_str}"
    res = Net::HTTP.get_response url

    doc = case res
          when Net::HTTPSuccess then XML::Document.string res.body
          else res.error!
          end

    metadata['describe-file-object'] = element_doc_as_str doc, "//P:object[@xsi:type='file']" 
    metadata['describe-event'] = element_doc_as_str doc, "//P:event"
    metadata['describe-agent'] = element_doc_as_str doc, "//P:agent" 
    metadata['describe-bitstream-objects'] = element_doc_as_str doc, "//P:object[@xsi:type='bitstream']"
    @wip.tags["describe-#{id}"] = Time.now.xmlschema
  end

  private

  def element_doc_as_str doc, xpath
    n = doc.find_first xpath, NS_PREFIX

    if n
      d = XML::Document.new
      d.root = d.import n
      d.to_s
    end

  end

end
