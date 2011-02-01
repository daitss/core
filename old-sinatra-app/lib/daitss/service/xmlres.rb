require 'curb'
require 'daitss/archive'

module Daitss

  class XmlRes

    def put_collection id
      url = "#{archive.xmlresolution_url}/ieids/#{id}"
      c = Curl::Easy.new url
      c.http_put ""
      (200..201).include? c.response_code or c.error("bad status")
      @url = url + '/'
    end

    def resolve_file f, base_uri
      c = Curl::Easy.new @url
      c.multipart_form_post = true
      c.http_post Curl::PostField.file('xmlfile', f)
      (200..201).include? c.response_code or c.error("bad status")

      doc = Nokogiri::XML c.body_str

      # event
      event = doc.at "//P:event", NS_PREFIX
      event or raise "no event found"
      event.at("//P:eventIdentifierValue", NS_PREFIX).content = "#{base_uri}/event/xmlresolution"
      event.at("//P:linkingObjectIdentifierValue", NS_PREFIX).content = base_uri
      event_doc = Nokogiri::XML(nil)
      event_doc << event
      event_xml = event_doc.root.serialize

      # agent
      agent = doc.at "//P:agent", NS_PREFIX
      agent or raise "no agent found"
      agent_doc = Nokogiri::XML(nil)
      agent_doc << agent
      agent_xml = agent_doc.root.serialize

      [event_xml, agent_xml]
    end

    def save_tarball f
      c = Curl::Easy.download(@url, f) { |c| c.follow_location = true }
      c.response_code == 200 or c.error("bad status")
    end

  end

end
