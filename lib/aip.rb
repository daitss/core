require 'uri'

require 'ingestable'
require 'described'
require 'transformable'
require 'planable'

class Snafu < StandardError; end

class DFile

  include Described
  include Transformable
  include Planable
  
  def initialize aip, path
    @aip = aip
    @path = path
  end
  
  def url
    URI.parse "#{@aip.url.to_s}/#{@path}"
  end
  
  def to_s
    url.to_s
  end
  
end

# File System based AIP
class Aip

  attr_reader :url

  include Ingestable

  def initialize url
    @url = URI.parse url
    raise "unsupported url: #{@url}" unless @url.scheme == 'file'
    raise "cannot locate package: #{url}" unless File.directory?(@url.path)
  end

  def descriptor
    File.join @url.path, 'descriptor.xml'
  end
  
  def files
    
    Dir.chdir(@url.path) do
      Dir["files/**/*"].map { |f| DFile.new self, f }
    end
    
  end

  def to_s
    url.to_s
  end
  
end
