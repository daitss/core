require 'daitss/archive'

module Daitss

  class Virus

    PATH = '/'

    def initialize f, uri
      @file = f
      @uri = uri
      @url = archive.viruscheck_url + PATH
    end

    def post
      c = Curl::Easy.new @url
      c.multipart_form_post = true
      data = Curl::PostField.file 'data', @file
      c.http_post data
      c.response_code == 200 or c.error("bad status")
      @doc = Nokogiri::XML c.body_str
    end

    def event
      event = @doc.at "//P:event", NS_PREFIX
      event or raise "no event found"
      event.at("//P:linkingObjectIdentifierValue", NS_PREFIX).content = @uri
      event.at("//P:eventIdentifierValue", NS_PREFIX).content = "#{@uri}/event/virus-check"
      doc = Nokogiri::XML(nil)
      doc << event.dup
      doc.root.serialize
    end

    def agent
      agent = @doc.at "//P:agent", NS_PREFIX
      agent or raise "no agent found"
      doc = Nokogiri::XML(nil)
      doc << agent.dup
      doc.root.serialize
    end

    def failed?
      @doc.search '//P:eventOutcome = "failure"', NS_PREFIX
    end

    def note
      @doc.at '//P:eventOutcomeDetailNote', NS_PREFIX
    end

  end

end
