require 'base64'
require 'digest/md5'
require "layout"

include Layout

module Store
  
  def stored?
    md_for_event? "Copy Stored"
  end
  
  def store!
    relative_path = File.basename(path)
    excludes = [POLY_DESCRIPTOR_FILE, FILE_MD_DIR, AIP_MD_DIR].map { |e| "--exclude #{File.join(relative_path, e)}" }.join ' '
    tardata = Dir.chdir(File.dirname(path)) { `tar #{excludes} -cf - #{ relative_path }` }
    storage_url = URI.parse "http://localhost:3000/one/data/#{relative_path}"
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
