require 'xml'
require 'db/daitss2.rb'

class AIPInPremis
  def processDatafile premis
    @df = Datafile.new
    @df.fromPremis premis
   
    # process all matched formats
    list = premis.find("premis:objectCharacteristics/premis:format", NAMESPACES)
    firstNode = true
    list.each do |node|
      format = Format.new
      format.fromPremis node
      puts format.inspect
      # determine if this format is already at our format table
      record = Format.first(:format_name => format.format_name)
      record = format if record.nil?      

      fileformat = FileFormat.new
      fileformat.datafile_id = @df.id
      fileformat.format_registry = record.registry
      fileformat.format_registry_id = record.registry_id  

      # first format element is designated for the file format.  Subsequent format elements are used for format profiles
      if (firstNode)
        fileformat.setPrimary
        firstNode = false
      else
        fileformat.setSecondary
      end
      puts record.inspect
      puts fileformat.inspect
    end
    
    # process object characteristic extension
    node = premis.find_first("premis:objectCharacteristicsExtension", NAMESPACES)
    if (node)
      this.processObjectCharacteristicExtension objExt
    end
    
    #TODO need storage data model
    @mdtype = premis.find_first("premis:objectCharacteristics/premis:fixity/premis:messageDigestAlgorithm", NAMESPACES).content
    @mdvalue = premis.find_first("premis:objectCharacteristics/premis:fixity/premis:messageDigest", NAMESPACES).content
  end

  def processObjectCharacteristicExtension objExt
    object = nil
    
    if aes = objExt.find_first("aes:audioObject", NAMESPACE)
      object = Audio.new
      object.fromPremis aes
    else if techmd = objExt.find_first("textMD", NAMESPACE)
      object = Text.new
      object.fromPremis techmd
    else if mix = objExt.find_first("mix:mix", NAMESPACE)
      object = Image.new
      object.fromPremis mix
    else if doc = objExt.find_first("document", NAMESPACE)
      object = Document.new
      object.fromPremis doc
    end
    
    object
  end
  def toDB
    @df.save
  end
end