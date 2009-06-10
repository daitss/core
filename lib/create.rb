require 'template'

class Aip

  # Create an AIP from a sip
  def Aip.from_sip path, sip_path

    # make the aip dir
    File.mkdir path

    Dir.chdir path do
      
      # make the layout
      File.mkdir 'files'
      File.mkdir 'aip-md'
      File.mkdir 'file-md'

      # make the base descriptor
      obj_id = File.basename sip_path
      open('descriptor.xml') { |io| io.write template_by_name('aip_descriptor').result(binding) }
    end
    
    # make the aip object
    aip = Aip.new path
    
    Dir.chdir sip_path do
      
      Dir['*'].each do |f| 
        open(f) { |io| aip.add_file io, f } 
      end
      
    end
    
  end
  
end