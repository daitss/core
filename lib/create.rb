require 'template'

class Aip

  # Create an AIP from a sip
  def Aip.make_from_sip path, sip_path

    # make the aip layout
    FileUtils::mkdir path
    
    ['files', 'aip-md', 'file-md'].each do |d| 
      FileUtils::mkdir File.join(path, d)
    end
    
    descriptor_file = File.join(path, "descriptor.xml")
    obj_id = File.basename sip_path
    open(descriptor_file, 'w') { |io| io.write template_by_name('aip_descriptor').result(binding) }    
    
    # make the aip object
    aip = Aip.new "file:#{path}"
    
    Dir.chdir sip_path do
      sip_files = Dir['*'].select { |f| File.file? f }
      sip_files.each do |f| 
        open(f) { |io| aip.add_file io, f } 
      end
      
    end
    
    aip
  end
  
end