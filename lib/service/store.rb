require 'base64'
require 'digest/md5'

module Store
  
  def stored?
    type = "Copy Stored"

    md_for(:digiprov).any? do |doc|
      doc.find_first("//premis:event[premis:eventType[normalize-space(.)='#{type}']]", NS_MAP)
    end
    
  end
  
  def store!
    tardata = Dir.chdir(File.dirname(path)) { `tar -cf - #{ File.basename(path) }` }

    storage_url = URI.parse "http://localhost:3000/one/data/#{File.basename(path)}"
    req = Net::HTTP::Put.new storage_url.request_uri
    req.body = tardata
    req['Content-MD5'] = Base64.encode64(Digest::MD5.digest(req.body)).chomp
    response = Net::HTTP.start(storage_url.host, storage_url.port) { |http| http.request(req) }
    
    val_doc = case response
    when Net::HTTPCreated
      raw = template_by_name('storage_event').result(binding)
      XML::Parser.string(raw).parse
    else
      raise "cannot store aip: #{response.code} #{response.msg}: #{response.body}"
    end
    
  end
  
end
