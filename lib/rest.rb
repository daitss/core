require 'net/http'

# Requires the response of host and port
module RESTfulResource
    
  # Delete a resource
  def delete(uri)
    request Net::HTTP::Delete.new(uri)
  end

  # Get a resource
  def get(uri)
    request Net::HTTP::Get.new(uri)
  end

  # Put a document
  def put(uri, body=nil, content_type="text/xml")
    req = Net::HTTP::Put.new uri
    req.content_type = content_type
    req.body = body
    request req
  end

  # Post a document to a uri
  def post(uri, body, content_type="text/xml")
    req = Net::HTTP::Post.new uri
    req.content_type = content_type
    req.body = body
    request req
  end

  protected

  def request(req)
    res = Net::HTTP.start(host, port) { |http| http.request req }

    case res
    when Net::HTTPSuccess
      res
      
    when Net::HTTPClientError
      raise "client error: #{res.code} #{res.message}"
      
    when Net::HTTPServerError
      raise "server error: #{res.code} #{res.message}"
      
    else
      raise "unexpected response: #{res}"
      
    end
    
  end

end
