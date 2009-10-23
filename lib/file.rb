require 'libxml'

require 'metadata'
require 'fileprocess'
require 'service/describe'
require 'service/transform'
require 'service/plan'

include LibXML

class DFile

  attr_reader :fid

  include FileProcess
  include Metadata
  include Service::Describe
  include Service::Plan
  include Service::Transform
  
  def initialize aip, id
    @aip = aip
    @fid = id
  end
  
  def path
    href = @aip.poly_descriptor_doc.find_first("//mets:file[@ID='#{@fid}']/mets:FLocat/@xlink:href", NS_MAP)
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

  def poly_descriptor_doc
    @aip.poly_descriptor_doc
  end

  def modify_poly_descriptor &block
    @aip.modify_poly_descriptor &block
  end

  
end
