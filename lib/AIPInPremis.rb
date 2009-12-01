require 'xml'
require 'db/daitss2.rb'

class AIPInPremis
  def initialize 
    @representations = Array.new
    @datafiles = Hash.new
    @bitstreams = Array.new
    @formats = Array.new
    @events = Array.new
    @agents = Array.new
  end

  def processRepresentation premis
    puts premis
    
    rep = Representation.new
    rep.fromPremis premis
    
    files = premis.find("premis:relationship", NAMESPACES)
    files.each do |f|
      dfid = f.find_first("premis:relatedObjectIdentification/premis:relatedObjectIdentifierValue", NAMESPACES).content
      df = @datafiles[dfid]
      puts df.inspect
      unless df.nil?
        rep.datafiles << df
        df.representations << rep
      end
    end
      
    @representations << rep
  end
  
  def processDatafile premis
    df = Datafile.new
    df.fromPremis premis

    # process all matched formats
    processFormats(df, premis)
    
    # process object characteristic extension
    node = premis.find_first("premis:objectCharacteristics/premis:objectCharacteristicsExtension", NAMESPACES)
    @obj = nil
    if (node)
      @obj = processObjectCharacteristicExtension(df, node)
    end
    @datafiles[df.id] = df

    # TODO need storage data model
    @mdtype = premis.find_first("premis:objectCharacteristics/premis:fixity/premis:messageDigestAlgorithm", NAMESPACES).content
    @mdvalue = premis.find_first("premis:objectCharacteristics/premis:fixity/premis:messageDigest", NAMESPACES).content
  end

  def processObjectCharacteristicExtension(p, objExt)
    object = nil

    if aes = objExt.find_first("aes:audioObject", NAMESPACES)
      object = Audio.new
      object.fromPremis aes
      p.audios << object
    elsif textmd = objExt.find_first("txt:textMD", NAMESPACES)
      object = Text.new
      object.fromPremis textmd
      p.texts << object
    elsif mix = objExt.find_first("mix:mix", NAMESPACES)
      object = Image.new
      object.fromPremis mix
      p.images << object
    elsif doc = objExt.find_first("doc:doc/doc:document", NAMESPACES)
      object = Document.new
      object.fromPremis doc
      puts p.inspect
      p.documents << object
    end

    object
  end

  def processFormats(p, premis)
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

       objectformat = ObjectFormat.new

       if (p.instance_of? Datafile)
         objectformat.datafile_id = p.id
       else
         objectformat.bitstream_id = p.id
       end
       
       puts record.inspect
       record.object_format << objectformat
       @formats << record
       # objectformat.format_id << record
       
       puts objectformat.inspect
       p.object_formats << objectformat
       
       # first format element is designated for the primary object (file/bitstream) format.  
       # Subsequent format elements are used for format profiles
       if (firstNode)
         objectformat.setPrimary
         firstNode = false
       else
         objectformat.setSecondary
       end
 
       puts objectformat.inspect

     end
  end
  
  def processBitstream premis
    bs = Bitstream.new
    bs.fromPremis premis

    processFormats(bs, premis)
    
    # process object characteristic extension
    node = premis.find_first("premis:objectCharacteristics/premis:objectCharacteristicsExtension", NAMESPACES)
    @obj = nil
    if (node)
      @obj = processObjectCharacteristicExtension(bs, node)
      puts @obj.inspect
    end
    
    @bitstreams << bs
  end

  def toDB
    @representations.each {|rep| rep.save }
  
    @formats.each {|fmt| fmt.save }

#   @datafiles.each {|dfid, df| df.save } -- not necessary since representations will save datafiles through associations

    @bitstreams.each {|bs| bs.save }
  end


  def processEvent premis
     puts premis

     event = Event.new
     event.fromPremis premis
       dfid = f.find_first("premis:linkingObjectIdentifier/premis:linkingObjectIdentifierValue", NAMESPACES).content
       df = @datafiles[dfid]
       puts df.inspect
       unless df.nil?
         event.datafiles << df
       end
     end

     @events << event
   end
   
end