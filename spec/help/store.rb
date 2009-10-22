Spec::Matchers.define :be_stored do

  match do |aip|
    storage_url = URI.parse "#{Config::Service['storage']}/#{File.basename aip.path}"
    req = Net::HTTP::Get.new storage_url.request_uri
    response = Net::HTTP.start(storage_url.host, storage_url.port) { |http| http.request(req) }
    Net::HTTPOK === response
  end

end
