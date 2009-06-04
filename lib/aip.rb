require 'open-uri'
require 'cgi'
require 'ingestable'

# determine the status of a package
module Status

  def ingested?
  end

  def rejected?
  end

  def snafu?
  end

end

# File System based AIP
class Aip

  attr_reader :url

  def initialize url
    @url = URI.parse url
    raise "unsupported url: #{@url}" unless @url.scheme == 'file'
    raise "cannot locate package: #{url}" unless File.directory?(@url.path)
  end

  def descriptor
    File.join @url.path, 'descriptor.xml'
  end
  
  def files
    Dir["#{@url.path}/**/*"]
  end

  def to_s
    url.to_s
  end
  
end

class Reject < StandardError
  alias_method :reasons, :message
end

class Snafu < StandardError; end
