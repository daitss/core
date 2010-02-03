require 'template'
require 'datafile'
require 'net/http'
require 'cgi'

class DataFile

  def transform url
    res = Net::HTTP.get_response URI.parse("#{url}?location=#{CGI::escape "file:#{File.expand_path datapath}"}")

    doc = case res
          when Net::HTTPSuccess then XML::Document.string(res.body)
          else res.error!
          end

    links = doc.find('/links/link').map do |node|
      link = node.content
      URI.join url, link
    end

    links.map do |link|
      res = Net::HTTP.get_response link

      case res
      when Net::HTTPSuccess then [res.body, File::extname(link.path)] 
      else res.error!
      end

    end

  end

end
