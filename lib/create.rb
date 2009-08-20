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
    
    Dir.chdir sip_path do
      # TODO handle arbitrary nested dirs (**/*)?
      sip_files = Dir['**/*'].select { |f| File.file? f }
      sip_files.each do |f| 
        open(f) { |io| aip.add_file io, f } 
      end
      
    end
    
    aip
  end
  
end