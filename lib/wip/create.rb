require 'libxml'
require 'wip'
require 'xmlns'

include LibXML

class Sip
  
  attr_reader :path, :owner_ids

  def initialize path
    @path = File.expand_path path
    @descriptor_doc = open(descriptor_file) { |io| XML::Document.io io  }
    @owner_ids = {}
    extract_owner_ids
  end

  def extract_owner_ids

    @descriptor_doc.find("/M:mets/M:fileSec//M:file[M:FLocat/@xlink:href]", NS_PREFIX).each do |node|
      f = node.find_first('M:FLocat', NS_PREFIX)['href']
      @owner_ids[f] = node['OWNERID'] if node['OWNERID']
    end

  end

  def descriptor_file
    descriptor_file = File.join @path, "#{name}.xml"
  end

  def name
    File.basename @path
  end

  def files

    Dir.chdir @path do
      Dir['**/*'].select { |f| File.file? f }.map { |f| f }.sort
    end

  end

end

class Wip

  # Create an AIP from a sip
  def Wip.make_from_sip path, uri, sip
    wip = Wip.new path, uri
    wip['sip-name'] = sip.name

    sip.files.each do |f|
      df = wip.new_datafile

      open(File.join(sip.path, f)) do |i| 
        buffer_size = 1024 * 1024 * 10
        buffer = ""

        df.open("w") do |o|

          while i.read(buffer_size, buffer)
            o.write buffer
          end

        end

      end

      df['sip-path'] = f
      df['owner-id'] = sip.owner_ids[f] if sip.owner_ids[f]
    end

    wip
  end

end
