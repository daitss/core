require 'open-uri'

module Ingestable
  
  def validate!
  end

  def store!
  end
  
end

class Aip

  def initialize url
    @url = URI.parse url
    raise "unsupported url: #{@url}" unless @url.scheme == 'file'
    raise "cannot locate package: #{url}" unless File.directory?(@url.path)
  end

  def files
    Dir["#{@url.path}/**/*"]
  end
  
  include Ingestable
end

class Reject < StandardError; end

