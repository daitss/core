class Sip

  def initialize path
    @path = File.expand_path path
  end

  def files

    Dir.chdir @path do
      sip_files = Dir['**/*'].select { |f| File.file? f }.each { |f| yield f }
    end

  end

  def owner_id f
    name = File.basename sip_path
    descriptor_file = File.join @path, "#{name}.xml"
    doc = open(descriptor_file) { |io| XML::Document.io io  }
    doc.find_first("//M:file[M:FLocat/@xlink:href='#{f}']/@ID", NS_PREFIX).value rescue nil
  end

end

class Wip

  # Create an AIP from a sip
  def Wip.make_from_sip path, sip
    wip = Wip.new path
   
    sip.files.each do |f|
        df = Wip.new_datafile
        FileUtis::mkdir_p File.dirname(df.path) unless File.dirname(f) == '.'
        FileUtils::cp f, df.path
        df.metadata['owner-id'] = sip.owner_id f
    end
    
    wip
  end
  
end
