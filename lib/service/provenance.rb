require 'cgi'
require 'libxml'
require "service/error"

include LibXML

module Service
  
  module Provenance
  
    def provenance_retrieved?
      metadata.has_key? 'external-provenance'
    end

    def retrieve_provenance!
      ask_service 'external-provenance', "#{Config::Service['provenance']}/events?location=#{CGI::escape @url.to_s}"
    end
  
    def rxp_provenance_retrieved?
      metadata.has_key? 'rxp-provenance'
    end

    def retrieve_rxp_provenance!
      ask_service 'rxp-provenance', "#{Config::Service['provenance']}/rxp?location=#{CGI::escape @url.to_s}"    
    end
  
    def representations_retrieved?
      @metadata.has_key? 'external-representations'
    end
  
    def retrieve_representations!
      ask_service 'external-provenance', "#{Config::Service['provenance']}/representations?location=#{CGI::escape to_s}"
    end
 
    private

    def ask_service key, url
      response = Net::HTTP.get_response URI.parse(url)

      case response
      when Net::HTTPSuccess
        metadata[key] = response.body
      when Net::HTTPNotFound 
        # do nothinkg if there is no metadata for this aip, maybe mark it not found somehowe
      else
        raise ServiceError, "cannot retrieve #{key} at #{url}: #{response.code} #{response.msg}: #{response.body}"
      end    

    end

  end

end
