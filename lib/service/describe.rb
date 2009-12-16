require 'service'

module Service
  
  module Describe

    def described?
      metadata.has_key? 'format-description'
    end
    
    def describe! 
      response = Net::HTTP.get_response URI.parse("#{CONFIG['description']}?location=#{CGI::escape to_s}")
    
      case response
      when Net::HTTPSuccess
        @metadata['format-description'] = XML::Parser.string(response.body).parse
      else
        raise Error, "cannot describe file: #{response.code} #{response.msg}: #{response.body}"
      end

    end

  end

end
