require 'uri'

require 'metadata'
require 'file'
require 'ingestable'
require 'validatable'

# File System based AIP
class Aip

  attr_reader :url

  include Metadata
  include Ingestable

  def initialize url
    @url = URI.parse url
    raise "unsupported url: #{@url}" unless @url.scheme == 'file'
    raise "cannot locate package: #{url}" unless File.directory?(@url.path)
  end
  
  def path
    @url.path
  end

  def descriptor_file
    File.join path, 'descriptor.xml'
  end
  
  def files
    doc = XML::Parser.file(descriptor_file).parse
    
    doc.find('//mets:file', NS_MAP).map do |file_node|
      DFile.new self, file_node['ID']
    end
    
  end

  def to_s
    url.to_s
  end
  
  def md_dir
    File.join path, 'md', 'aip'
  end
      
  def write_reject_info e
    reject_info_file = File.join(path, 'REJECT')
    
    open(reject_info_file, "w") do |io|
      io.puts Time.now

      e.reasons.each do |r|
        io.puts "%s %s: %s" % [ r[:time].strftime('%c'), r[:type], r[:message] ]
      end

    end
    
  end

  def write_snafu_info e
    
    open(File.join(path, 'SNAFU'), "w") do |io|
      io.puts Time.now
      io.puts e.message
      io.puts e.backtrace
    end
    
  end
  
  
end
