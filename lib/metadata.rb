require 'libxml'
require 'next'

include LibXML

# depends on package_dir, md_dir and descriptor_file methods
module Metadata
  
  METS_MD_SECTIONS = [:digiprov, :tech, :rights, :source]
  
  # Creates a new metadata file for the incoming document and references it in the descriptor
  def add_md type, md_doc
    raise "invalid meta data type: #{type.id2name}" unless METS_MD_SECTIONS.include? type
    
    # make a new metadata file for the incoming metadata
    file_base = type.id2name
    current_md_files = Dir[File.join(md_dir, "#{file_base}-*.xml")]
    next_md_file = next_in_set current_md_files, /#{file_base}-(\d+).xml/
    md_file = File.join md_dir, "#{file_base}-#{next_md_file}.xml"
    raise 'cannot write metadata, file already exists #{md_file}' if File.exist? md_file
    md_doc.save md_file  

    # reference the file in the aip descriptor
    des_doc = XML::Parser.file(descriptor_file).parse
    amdSec = des_doc.find_first("//mets:amdSec", NS_MAP)
    amdSec << make_md_ref(type, md_file, des_doc)
    des_doc.save descriptor_file
  end
  
  # Return a list of meta data files for the specified type
  def md_files_for type
    pattern = File.join md_dir, "#{type.id2name}-*.xml"
    Dir[pattern]
  end
  
  # Returns a list of xml documents for the specified type
  def md_for type
    md_files_for(type).map { |f| XML::Parser.file(f).parse }
  end
    
  # Adds an RXP meta data record, overwrites if already present
  def add_rxp_md doc
    raise "must be a PREMIS document" unless doc.root.namespaces.namespace.to_s == NS_MAP['premis']
    
    md_file = File.join md_dir, "rxp.xml"
    raise 'cannot write metadata, file already exists #{md_file}' if File.exist? md_file
    doc.save md_file
    
    # reference the file in the aip descriptor
    des_doc = XML::Parser.file(descriptor_file).parse
    amdSec = des_doc.find_first("//mets:amdSec", NS_MAP)
    md_ref = make_md_ref(:digiprov, md_file, des_doc)
    md_ref["TYPE"] = 'PREMIS'
    md_ref["LABEL"] = 'RXP'
    amdSec << md_ref
    des_doc.save descriptor_file
  end
  
  def rxp_md_file
    File.join md_dir, "rxp.xml"
  end
    
  protected
  
  # Return a METS mdSecType instance that references the metadata file
  def make_md_ref type, md_file, doc
    relative_path = md_file[(package_dir.length + 1)..-1]

    # the section
    mdSec = XML::Node.new "#{type.id2name}MD"    
    md_ids = doc.find("//mets:#{type.id2name}MD/@ID", NS_MAP).map { |node| node.value }
    mdSec['ID'] = next_in_set(md_ids, /#{type.id2name}-(\d+)/).to_s
    
    # the reference
    mdRef = XML::Node.new 'mdRef'
    mdRef['MDTYPE'] = 'PREMIS'
    mdRef['xlink:href'] = relative_path
    mdSec << mdRef
    
    mdSec
  end
  
end