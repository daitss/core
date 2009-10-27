require 'layout'
require 'template'

class Aip

  # Create an AIP from a sip
  def Aip.make_from_sip path, sip_path
    path = File.expand_path path
    
    # make the aip layout
    FileUtils::mkdir path
    
    [FILES_DIR, AIP_MD_DIR, FILE_MD_DIR].each do |d| 
      FileUtils::mkdir File.join(path, d)
    end
    
    # make blank descriptor
    descriptor_file = File.join path, POLY_DESCRIPTOR_FILE
    obj_id = File.basename sip_path
    open(descriptor_file, 'w') { |io| io.write template_by_name('aip_descriptor').result(binding) }
    
    # make the aip object
    aip = Aip.new "file:#{path}"
    
    # sip descriptor file
    sip_descriptor_file = File.join sip_path, "#{obj_id}.xml"
    
    Dir.chdir sip_path do
      sip_files = Dir['**/*'].select { |f| File.file? f }
      sip_files.each do |f|
        owner_id = extract_owner_id sip_descriptor_file, f
        open(f) { |io| aip.add_file io, f, owner_id }
      end
      
    end
    
    aip
  end
  
end

def extract_owner_id sip_descriptor_file, f
  doc = open(sip_descriptor_file) { |io| XML::Document.io(io) }
  doc.find_first("//mets:file[mets:FLocat/@xlink:href='#{f}']/@ID", NS_MAP).value rescue nil
end
