require 'service/error'

module Service
  
  module Plan

    def migration
      transform_url =  "#{CONFIG['actionplan']}/migration?description=#{CGI::escape "file:#{obj_file}" }"
    end

    def normalizations
      ask_for_redirect "#{CONFIG['actionplan']}/normalization?description=#{CGI::escape "file:#{obj_file}" }"
    end

    private

    def transform url
      response = Net::HTTP.get_response URI.parse(url)

      transform_url = case response
                      when Net::HTTPRedirection
                        response['location']
                      else
                        raise Service::Error, "no transformation given: #{response.code} #{response.msg}: #{response.body}"
                      end



    end

        
  end
  
end
