require 'xml'
require 'db/daitss2.rb'

class AIPInPremis
  def initialize 
    @int_entity = Intentity.new
    @int_entity.fromPremis
    @representations = Array.new
    @datafiles = Hash.new
    @bitstreams = Array.new
    @formats = Array.new
    @events = Array.new
    @agents = Hash.new
  end

  def processRepresentation premis
    rep = Representation.new
    rep.fromPremis premis

    files = premis.find("premis:relationship", NAMESPACES)
    files.each do |f|
      dfid = f.find_first("premis:relatedObjectIdentification/premis:relatedObjectIdentifierValue", NAMESPACES).content
      df = @datafiles[dfid]
      puts df.inspect
      unless df.nil?
        # rep.datafiles << df
        df.representations << rep
      end
    end

    @int_entity.representations << rep
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
      @obj.bitstream_id = :null
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
        objectformat.bitstream_id = :null
      else
        objectformat.bitstream_id = p.id
        objectformat.datafile_id = :null
      end

      puts record.inspect
      record.object_format << objectformat
      @formats << record
      # objectformat.format_id << record

      puts objectformat.inspect
      p.object_format << objectformat

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
      @obj.datafile_id = :null
      puts @obj.inspect
    end
    @bitstreams << bs
  end

  def processAgent premis
    agent = Agent.new
    agent.fromPremis premis
    @agents[agent.id] = agent
  end

  def processEvent premis
    id = premis.find_first("premis:linkingObjectIdentifier/premis:linkingObjectIdentifierValue", NAMESPACES)
    # check if this event related to a datafile
    df = @datafiles[id.content] unless id.nil?

    agent_id = premis.find_first("premis:linkingAgentIdentifier/premis:linkingAgentIdentifierValue", NAMESPACES)
    agent = @agents[agent_id.content] unless agent_id.nil?   

    unless df.nil?
      event = DatafileEvent.new
      event.fromPremis premis
      event.setRelatedObject id.content
      agent.events << event unless agent.nil?
      @events << event
    end  
  end

  def toDB
    Intentity.transaction do 
      # @int_entity.save
      @formats.each { |fmt| raise 'error saving format records'  unless fmt.save }

      # @representations.each {|rep| rep.save }
      # not necessary since representations will save datafiles through associations
      @datafiles.each {|dfid, df|  raise 'error saving datafile records' unless  df.save } 
      @bitstreams.each {|bs|  raise 'error saving bitstream records' unless bs.save }
      @agents.each {|id, ag|  raise 'error saving agent records' unless ag.save }
      @events.each {|e|  raise 'error saving event records' unless e.save }
    end
    
  end

end