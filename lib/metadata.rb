require 'libxml'
require 'next'

include LibXML

# depends on package_dir, md_dir and poly_descriptor_file methods
module Metadata
  
  # XXX technically, rights and source would be valid metadata document types,
  # but here we expect either digiprov or tech
  METS_MD_SECTIONS = [:digiprov, :tech]
  
  # Creates a new metadata file for the incoming document and references it in the descriptor
  # Returns the id of the newly created meta data section
  def add_md type, doc
    raise "invalid meta data type: #{type.id2name}" unless METS_MD_SECTIONS.include? type
    md_file = make_md_file! type, doc
    make_md_ref! type, md_file
  end
  
  # link to a file
  def add_file_md_link md_id
    add_admid_ref md_id, "//mets:file[@ID='#{@fid}']"
  end

  # link to the div's structmap
  def add_div_md_link md_id
    add_admid_ref md_id, "//mets:structMap/mets:div"
  end
  
  # adds a ADMID ref to a file, should not be called from non-file
  def add_admid_ref md_id, xpath
    modify_poly_descriptor do |doc|
      node = doc.find_first xpath, NS_MAP
      admids = node['ADMID'] ? node['ADMID'].split(%r{\s+}) : []
      admids << md_id
      node['ADMID'] = admids.join ' '
    end
    
  end
  
  # Return a list of meta data files for the specified type
  def md_files_for type
    pattern = File.join md_dir, "#{type.id2name}-*.xml"
    Dir[pattern]
  end
  
  # Returns a if a premis events that match the event type exists
  def md_for_event? type
    xpath = "//premis:event[premis:eventType[normalize-space(.)='#{type}']]"
    md_for(:digiprov).any? { |doc| doc.find_first xpath, NS_MAP }
  end
  
  # Returns a document for the mets ID
  def md_for_id id
    href = poly_descriptor_doc.find_first "//mets:*[@ID='#{id}']/mets:mdRef/@xlink:href", NS_MAP
    f = File.join(@aip.path, href.value)
    open(f) { |io| XML::Parser.io(io).parse }
  end
  
  # Returns a list of xml documents for the specified type
  def md_for type
    md_files_for(type).map { |f| open(f) { |io| XML::Parser.io(io).parse } }
  end
    
  # Saves RXP metadata. Returns the ID of the created metadata section
  def add_rxp_md doc
    raise "must be a PREMIS document" unless doc.root.namespaces.namespace.to_s == NS_MAP['premis']
    doc.save rxp_md_file
    
    make_md_ref! :digiprov, rxp_md_file, 'RXP'
  end
  
  # Returns the path to the rxp meta data file
  def rxp_md_file
    File.join md_dir, "rxp.xml"
  end

  # add a representation
  def add_representation_md rname, doc
    raise "must be a PREMIS document" unless doc.root.namespaces.namespace.to_s == NS_MAP['premis']
    md_file = File.join md_dir, "#{rname}.xml".downcase
    doc.save md_file

    make_md_ref! :tech, md_file do |md_sec|
      md_sec["TYPE"] = 'PREMIS'
      md_sec.first["LABEL"] = rname.upcase
    end
    
  end
      
  private
      
  # make a meta data file in the package. return the path to the file
  def make_md_file! type, doc
    file_base = type.id2name
    current_md_files = Dir[File.join(md_dir, "#{file_base}-*.xml")]
    next_md_file = next_in_set current_md_files, /#{file_base}-(\d+).xml/
    md_file = File.join md_dir, "#{file_base}-#{next_md_file}.xml"
    raise 'cannot write metadata, file already exists #{md_file}' if File.exist? md_file
    doc.save md_file
    md_file
  end
  
  # make a METS mdRef to a file. return the id of the mdRef. if a block is
  # given then assembly of the amdSec and the metadata section is expected to
  # happen in the block given.
  def make_md_ref! type, md_file, label=nil
    
    modify_poly_descriptor do |des_doc|
      md_sec = make_md_sec_ref type, md_file, des_doc, label
      amd_sec = des_doc.find_first("//mets:amdSec", NS_MAP)      
      yield md_sec if block_given?
      
      if amd_sec.empty? or type == :digiprov
        amd_sec << md_sec
      elsif type == :tech
        amd_sec.first.prev = md_sec
      end
      
      md_sec['ID']
    end
    
  end
  
  # Return a METS mdSecType instance that references the metadata file
  def make_md_sec_ref type, md_file, doc, label
    relative_path = md_file[(package_dir.length + 1)..-1]

    # the section
    md_name = type.id2name
    mdSec = XML::Node.new "#{md_name}MD"
    md_ids = doc.find("//mets:#{md_name}MD/@ID", NS_MAP).map { |node| node.value }
    mdSec['ID'] = md_name + '-' + next_in_set(md_ids, /#{md_name}-(\d+)/).to_s

    # the reference
    mdRef = XML::Node.new 'mdRef'
    mdRef['MDTYPE'] = 'PREMIS'
    mdRef["LABEL"] = label if label
    mdRef['xlink:href'] = relative_path
    mdSec << mdRef
    
    mdSec
  end
  
end