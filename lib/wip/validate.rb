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
    metadata['validate-event'] = validate_event doc
    metadata['validate-event-full'] = doc
    metadata['validate-agent'] = validate_agent doc
    raise Reject, rr unless rr.empty?
  end

  private

  def ask_validation
    url = URI.parse Daitss::CONFIG['viruscheck-url']
    req = Net::HTTP::Get.new url.path
    req.form_data = { 'location' => "file:#{File.expand_path path}" }

    res = Net::HTTP.start(url.host, url.port) do |http|
      http.read_timeout = Daitss::CONFIG['http-timeout']
      http.request(req)
    end

    case res
    when Net::HTTPSuccess then res.body
    else res.error!
    end

  end

  def reject_reasons doc
    msg = StringIO.new
    doc.find("//P:event", NS_PREFIX).map do |e|
      if %w(failure missing mismatch invalid failed).include? e.find_first("P:eventOutcomeInformation/P:eventOutcome", NS_PREFIX).content
        msg.puts "type: #{e.find_first('P:eventType', NS_PREFIX).content.strip}"
        msg.puts "time: #{Time.parse(e.find_first('P:eventDateTime', NS_PREFIX).content.strip).xmlschema 4}"
        msg.puts "message: #{e.find_first('P:eventOutcomeInformation/P:eventOutcome', NS_PREFIX).content.strip}"
        msg.puts
      end
    end

    msg.string
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
