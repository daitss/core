require 'libxml'
require 'wip'
require 'xmlns'

include LibXML

class Sip
  
  attr_reader :path

  def initialize path
    @path = File.expand_path path
  end

  def name
    File.basename @path
  end

  def files

    Dir.chdir @path do
      Dir['**/*'].select { |f| File.file? f }.map { |f| f }.sort
    end

  end

  def owner_id f
    name = File.basename @path
    descriptor_file = File.join @path, "#{name}.xml"
    doc = open(descriptor_file) { |io| XML::Document.io io  }
    doc.find_first("//M:file[M:FLocat/@xlink:href='#{f}']/@OWNERID", NS_PREFIX).value rescue nil
  end

end

class Wip

  # Create an AIP from a sip
  def Wip.make_from_sip path, uri, sip
    wip = Wip.new path, uri
    wip['sip-name'] = sip.name

    sip.files.each do |f|
      df = wip.new_datafile
      open(File.join(sip.path, f)) { |i| df.open("w") { |o| o.write i.read } }
      df['sip-path'] = f
      owner_id = sip.owner_id f
      df['owner-id'] = owner_id if owner_id
    end

    wip
  end

end
