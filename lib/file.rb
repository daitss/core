require 'libxml'

require 'metadata'
require 'described'
require 'transformable'
require 'planable'

include LibXML

class DFile

  include Metadata
  include Described
  include Transformable
  include Planable
  
  def initialize aip, id
    @aip = aip
    @fid = id
  end
  
  def path
    doc = XML::Parser.file(descriptor_file).parse
    href = doc.find_first("//mets:file[@ID='#{@fid}']/mets:FLocat/@xlink:href", NS_MAP)
    href.value.strip
  end
  
  def package_dir
    @aip.package_dir
  end
  
  def url
    URI.parse "#{@aip.url.to_s}/#{path}"
  end
  
  def to_s
    url.to_s
  end
  
  def md_dir
    File.join @aip.path, 'file-md', @fid
  end
  
  def descriptor_file
    @aip.descriptor_file
  end
  
end
