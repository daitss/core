require 'cgi'
require 'libxml'
require 'xmlns'
require 'net/http'

include LibXML

class Reject < StandardError; end

class Wip

  def validate!
    doc = XML::Document.string ask_validation
    rr = reject_reasons doc
    raise Reject, rr unless rr.empty?
    metadata['validate-event'] = validate_event doc
    metadata['validate-agent'] = validate_agent doc
    tags['validate'] = Time.now.xmlschema
  end

  private

  def ask_validation
    url = URI.parse "#{CONFIG['validation-url']}?location=#{CGI::escape "file:#{File.expand_path path}" }"
    req = Net::HTTP::Get.new url.request_uri

    res = Net::HTTP.start(url.host, url.port) do |http|
      http.read_timeout = 10 * 60
      http.request(req)
    end

    case res
    when Net::HTTPSuccess then res.body
    else res.error!
    end

  end

  def reject_reasons doc
    xpath = "//P:event[P:eventOutcomeInformation/P:eventOutcome = 'failure' ]"

    doc.find(xpath, NS_PREFIX).map do |e|
      { :type => e.find_first('P:eventType', NS_PREFIX).content.strip,
        :time => Time.parse(e.find_first('P:eventDateTime', NS_PREFIX).content.strip),
        :message => e.find_first('P:eventOutcomeInformation/P:eventOutcome', NS_PREFIX).content.strip }
    end

  end

  def validate_event doc
    xpath = "//P:event[P:eventType = 'comprehensive validation']"
    n = doc.find_first xpath, NS_PREFIX

    if n
      d = XML::Document.new
      d.root = d.import n
      d.root.to_s
    end

  end

  def validate_agent doc
    xpath = "//P:agent[P:agentName = 'daitss validation service']"
    n = doc.find_first xpath, NS_PREFIX

    if n
      d = XML::Document.new
      d.root = d.import n
      d.root.to_s
    end
  end

end
