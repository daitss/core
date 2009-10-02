require 'xml'
require 'db/daitss2.rb'

class FileObject
  def initialize
    @profiles = Array.new
  end

  def fromPremis premis
    @id = premis.find_first("premis:objectIdentifier/premis:objectIdentifierValue", NAMESPACES).content
    puts @id
    @fsize = premis.find_first("premis:objectCharacteristics/premis:size", NAMESPACES).content
    puts @fsize

  
    list = premis.find("premis:objectCharacteristics/premis:format", NAMESPACES)

    firstNode = true
    list.each do |node|
      # first format element is designated for the file format.  Subsequent format elements are used for format profiles
      if (firstNode)
        @formatName = node.find_first("premis:formatDesignation/premis:formatName", NAMESPACES).content
        if node.find_first("premis:formatDesignation/premis:formatVersion", NAMESPACES)
          @formatVersion = node.find_first("premis:formatDesignation/premis:formatVersion", NAMESPACES).content
        end

        if  node.find_first("premis:formatRegistry", NAMESPACES)
          @formatRegistry = node.find_first("premis:formatRegistry/premis:formatRegistryName", NAMESPACES).content +
          node.find_first("premis:formatRegistry/premis:formatRegistryKey", NAMESPACES).content
        end
        firstNode = false
      else
        #TODO format...how to record format profiles?
        @profiles << node.find_first("premis:formatDesignation/premis:formatName", NAMESPACES).content
      end
    end
    
    puts @profiles.inspect
    
    # creating app. info
    node = premis.find_first("premis:objectCharacteristics/premis:creatingApplication/premis:creatingApplicationName", NAMESPACES)
    @creator_prog = node.content if node
    
    node = premis.find_first("premis:objectCharacteristics/premis:creatingApplication/premis:dateCreatedByApplication", NAMESPACES)
    @create_date = node.content if node
    
    #TODO  need storage data model
    @mdtype = premis.find_first("premis:objectCharacteristics/premis:fixity/premis:messageDigestAlgorithm", NAMESPACES).content
    @mdvalue = premis.find_first("premis:objectCharacteristics/premis:fixity/premis:messageDigest", NAMESPACES).content
  end

  def toDB
    df = Datafile.new
    df.id = @id
    df.size = @fsize.to_i
    df.format_name = @formatName
    df.format_version = @formatVersion
    df.format_registry = @formatRegistry
    df.create_date = @create_date if @create_date
    df.creator_prog = @creator_prog if @creator_prog
    df.original_path = ""

    df.save
  end
end