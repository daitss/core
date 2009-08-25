require 'libxml'

require 'metadata'
require 'fileprocess'
require 'service/describe'
require 'service/transform'
require 'service/plan'

include LibXML

class DFile

  include FileProcess
  include Metadata
  include Describe
  include Plan
  include Transform
  
  def initialize aip, id
    @aip = aip
    @fid = id
  end
  
  def path
    doc = XML::Parser.file(poly_descriptor_file).parse
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
    File.join @aip.file_md_dir , @fid
  end
  
  def poly_descriptor_file
    @aip.poly_descriptor_file
  end

  def modify_poly_descriptor &block
    @aip.modify_poly_descriptor &block
  end

  
end
