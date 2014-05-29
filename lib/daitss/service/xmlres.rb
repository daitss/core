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
    
    #remove a tar collection from xmlresolution
    def remove_collection id
      url = "#{archive.xmlresolution_url}/ieids/remove/#{id}"
      c = Curl::Easy.new url
      c.http_delete
      (200..301).include? c.response_code or c.error("bad status")
    end

    def resolve_file df
      filepath = df.metadata["sip-path"] ? df.metadata["sip-path"] : df.metadata["aip-path"]

      c = Curl::Easy.new @url
      c.multipart_form_post = true
      c.http_post Curl::PostField.file('xmlfile', df.data_file, File.basename(filepath))
      (200..201).include? c.response_code or c.error("bad status: #{c.response_code} -- #{c.body_str}")

      doc = Nokogiri::XML c.body_str

      # event
      event = doc.at "//P:event", NS_PREFIX
      event or raise "no event found"
      event.at("//P:eventIdentifierValue", NS_PREFIX).content = "#{df.uri}/event/xmlresolution"
      event.at("//P:linkingObjectIdentifierValue", NS_PREFIX).content = df.uri
      event_doc = Nokogiri::XML(nil)
      event_doc << event

      event_doc.remove_namespaces! 
      event_doc.root["xmlns"] = "info:lc/xmlns/premis-v2"

      event_xml = event_doc.root.serialize

      # agent
      agent = doc.at "//P:agent", NS_PREFIX
      agent or raise "no agent found"
      agent_doc = Nokogiri::XML(nil)
      agent_doc << agent

      agent_doc.remove_namespaces!
      agent_doc.root["xmlns"] = "info:lc/xmlns/premis-v2"

      agent_xml = agent_doc.root.serialize

      [event_xml, agent_xml]
    end

    def save_tarball f
      c = Curl::Easy.download(@url, f) { |c| c.follow_location = true }
      c.response_code == 200 or c.error("bad status")
    end

  end

end
