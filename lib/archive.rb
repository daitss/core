require 'nokogiri'
require 'uri'
require 'rest'
require 'aip'

module Daitss
  
  # Represents a DAITSS2 AIP Resource Instance
  class Archive

    include RESTfulResource

    # create a new archive object based at url
    def initialize(url)
      @url = URI.parse url
    end

    def host
      @url.host
    end

    def port
      @url.port
    end

    # create an AIP from the sip on the file system
    def create_aip(tgz_data)
      response = post "/archive", tgz_data, "application/tar"
      Aip.new self, response["Location"] # rfc 2616/14.30 location header
    end

    def url
      @url.to_s
    end

    # Return a list of Aips that are incomplete
    def incompletes
      parse_aip_list "_incompletes"
    end

    # Return a list of Aips that are rejected
    def rejects
      parse_aip_list "_rejects"
    end

    # Return a list of Aips that are snafus
    def snafus
      parse_aip_list "_snafus"
    end

    protected

    def parse_aip_list(path)
      response = get "#{@url}/#{path}"
      doc = Nokogiri::XML response.body
      doc.xpath("/*/aip/@url").map { |node| Aip.new self, node.content }
    end

  end
  
end
