require 'datafile'

class DataFile

  def virus_check!
    url = URI.parse "#{Daitss::CONFIG['validation-url']}"
    req = Net::HTTP::Post.new url.path
    req.set_form_data 'data' => open { |io| io.read }

    res = Net::HTTP.start(url.host, url.port) do |http|
      http.read_timeout = Daitss::CONFIG['http-timeout']
      http.request req
    end

    res.error! unless Net::HTTPSuccess === res
    doc = XML::Document.string res.body
    extract_event doc
    extract_agent doc
  end

  def extract_event doc
    event = doc.find_first("//P:event", NS_PREFIX)
    event.find_first("//P:linkingObjectIdentifierValue", NS_PREFIX).content = uri
    event.find_first("//P:eventIdentifierValue", NS_PREFIX).content = "#{uri}/event/virus-check"
    e_doc = XML::Document.new
    e_doc.root = e_doc.import event
    metadata['virus-check-event'] = e_doc.root.to_s
  end

  def extract_agent doc
    agent = doc.find_first("//P:agent", NS_PREFIX)
    a_doc = XML::Document.new
    a_doc.root = a_doc.import agent
    metadata['virus-check-agent'] = a_doc.root.to_s
  end

end
