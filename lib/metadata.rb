require 'libxml'

include LibXML

# depends on package_dir, md_dir and descriptor_file methods
module Metadata
  
  METS_MD_SECTIONS = [:digiprov, :tech, :rights, :source]
  
  # Creates a new metadata file for the incoming document and references it in the descriptor
  def add_md type, md_doc
    raise "invalid meta data type: #{type.id2name}" unless METS_MD_SECTIONS.include? type
    
    # make a new file
    md_file = next_md_file type
    raise 'cannot write metadata, file already exists #{md_file}' if File.exist? md_file
    md_doc.save md_file

    # reference it in the descriptor
    des_doc = XML::Parser.file(descriptor_file).parse
    amdSec = des_doc.find_first("//mets:amdSec", NS_MAP)

    mdSec = XML::Node.new "#{type.id2name}MD"
    amdSec << mdSec
    
    mdRef = XML::Node.new 'mdRef'
    mdRef['MDTYPE'] = 'PREMIS'
    relative_path = md_file[(package_dir.length+1)..-1]
    mdRef['xlink:href'] = relative_path
    mdSec << mdRef
    
    des_doc.save descriptor_file
  end
  
  
  # Retruns a list of xml documents for the specified type
  def md_for type
    pattern = File.join md_dir, "#{type.id2name}-*.xml"
    Dir[pattern].map { |f| XML::Parser.file(f).parse }
  end
  
  protected
  
  def next_md_file type
    file_base = type.id2name
    pattern = File.join md_dir, "#{file_base}-*.xml"
    
    taken_nums = Dir[pattern].map do |f| 
      
      if File.basename(f) =~ /#{file_base}-(\d+).xml/
        $1.to_i
      else
        -1
      end
      
    end
    
    next_num = if taken_nums.empty?
      0
    else
      taken_nums.compact.max + 1
    end
    
    File.join md_dir, "#{file_base}-#{next_num}.xml"
  end
  
end