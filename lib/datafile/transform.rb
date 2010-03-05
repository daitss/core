require 'template'
require 'datafile'
require 'net/http'
require 'cgi'

class DataFile

  def transform url
    url = URI.parse url
    req = Net::HTTP::Get.new url.path
    req.form_data = { 'location' => "file:#{File.expand_path datapath}" }

    res = Net::HTTP.start(url.host, url.port) do |http|
      http.read_timeout = Daitss::CONFIG['http-timeout']
      http.request req
    end


    doc = case res
          when Net::HTTPSuccess then XML::Document.string(res.body)
          else res.error!
          end

    links = doc.find('/links/link').map do |node|
      link = node.content
      url + link
    end

    raise "no transformations occurred" if links.empty?

    links.map do |link|
      req = Net::HTTP::Get.new link.path

      res = Net::HTTP.start(url.host, url.port) do |http|
        http.read_timeout = Daitss::CONFIG['http-timeout']
        http.request req
      end

      case res
      when Net::HTTPSuccess then [res.body, File::extname(link.path)] 
      else res.error!
      end

    end

  end

end
