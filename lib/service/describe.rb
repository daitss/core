require 'datafile'
require 'net/http'
require 'cgi'

class DataFile

  def described?
    @wip.tags.has_key? "describe-#{id}"
  end

  def describe! 
    file_url = URI.join 'file:/', File.expand_path(datapath)
    url = URI.join CONFIG['description-url'], "?location=#{CGI::escape file_url.to_s}"
    res = Net::HTTP.get_response url

    doc = case res
          when Net::HTTPSuccess then XML::Document.string res.body
          else res.error!
          end

    metadata['describe-file-object'] = describe_file_object doc
    metadata['describe-event'] = describe_event doc
    metadata['describe-agent'] = describe_agent doc
    metadata['describe-bitstream-objects'] = describe_bitstream_objects doc
    @wip.tags["describe-#{id}"] = Time.now.xmlschema
  end

  private

  def describe_file_object doc
    doc.find_first("//P:object[@xsi:type='file']", NS_PREFIX).to_s
  end

  def describe_event doc
    doc.find_first("//P:event", NS_PREFIX).to_s
  end

  def describe_agent doc
    doc.find_first("//P:agent", NS_PREFIX).to_s
  end

  def describe_bitstream_objects doc
    doc.find("//P:object[@xsi:type='bitstream']", NS_PREFIX).inject("") { |str,node| str + node.to_s }
  end

end
