require 'open-uri'

# makes an aip ingestable
module Ingestable

  def ingest!
    validate
    process_files
    aip.store
  end

  def validate
  end

  def process_files
    new_files = []

    aip.files.each do |file|
      file.describe!
      file.plan!
      new_files << file.transform if file.has_transformation?
    end
    
  end
  
  def store
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

end

class Reject < StandardError; end

