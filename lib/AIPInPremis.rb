require 'xml'
require 'db/daitss2.rb'

class AIPInPremis
  def initialize 
    @int_entity = Intentity.new
    @int_entity.fromPremis
    @representations = Array.new
    @datafiles = Hash.new
    @bitstreams = Hash.new
    @formats = Hash.new
    @events = Hash.new
    @agents = Hash.new
    @relationships = Array.new
  end

  def processRepresentation premis
    rep = Representation.new
    rep.fromPremis premis

    files = premis.find("premis:relationship", NAMESPACES)
    files.each do |f|
      dfid = f.find_first("premis:relatedObjectIdentification/premis:relatedObjectIdentifierValue", NAMESPACES).content
      df = @datafiles[dfid]
      unless df.nil?
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
      # create a temporary format record with the info. from the premis
      newFormat = Format.new
      newFormat.fromPremis node
      puts newFormat.inspect

      # only create a new format record if the format has NOT been seen before, both 
      # in format table and in the @formats hash
      format = Format.first(:format_name => newFormat.format_name)
      # if it's not already in the format table, check if it was processed earlier.
      format = @formats[newFormat.format_name] if format.nil?
     
      # create a new format record since the format name has not been seen before. 
      format = newFormat if format.nil?     

      objectformat = ObjectFormat.new

      if (p.instance_of? Datafile)
        objectformat.datafile_id = p.id
        objectformat.bitstream_id = :null
      else
        objectformat.bitstream_id = p.id
        objectformat.datafile_id = :null
      end

      puts format.inspect
      format.object_format << objectformat
      @formats[format.format_name] = format
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
    @bitstreams[bs.id] = bs
  end

  def processAgent premis
    agent = Agent.new
    agent.fromPremis premis
    @agents[agent.id] = agent
  end

  def processEvent premis
    id = premis.find_first("premis:linkingObjectIdentifier/premis:linkingObjectIdentifierValue", NAMESPACES)
    # make sure this event related to a datafile
    df = @datafiles[id.content] unless id.nil?

    agent_id = premis.find_first("premis:linkingAgentIdentifier/premis:linkingAgentIdentifierValue", NAMESPACES)
    agent = @agents[agent_id.content] unless agent_id.nil?   

    unless df.nil?
      event = DatafileEvent.new
      event.fromPremis premis
      event.setRelatedObject id.content
      #associate agent to the event
      agent.events << event unless agent.nil?
      @events[event.id] = event
    end  
  end
  
  def processRelationship(premis)
    # find the file id
    dfid = premis.find_first("premis:objectIdentifier/premis:objectIdentifierValue", NAMESPACES).content
    relationship_element = premis.find_first("premis:relationship", NAMESPACES)

    puts relationship_element
    # check if there is a valid datafile and there is a relationship associated with it
    unless (@datafiles[dfid].nil? || relationship_element.nil?)
      type = relationship_element.find_first("premis:relationshipType", NAMESPACES).content
      subtype = relationship_element.find_first("premis:relationshipSubType", NAMESPACES).content

      # check if this relationship link to an event
      event_id = relationship_element.find_first("premis:relatedEventIdentification/premis:relatedEventIdentifierValue", NAMESPACES)

      # find the event that ties to this relationship
      event = @events[event_id.content] unless event_id.nil?
      # only create relationship record if there is a valid linking event and it is
      # for derived relationships such as normalization and migration.
      if (type.eql?("derivation") && subtype.eql?("has source"))
        unless (event.nil?)
          relationship = Relationship.new      
          relationship.fromPremis(dfid, event.e_type, relationship_element)
          @relationships << relationship
        end
        # process whole-part relationship among datafile and bitstreams
       elsif (type.eql?("structural") && subtype.eql?("includes"))
        bsid = relationship_element.find_first("premis:relatedObjectIdentification/premis:relatedObjectIdentifierValue", NAMESPACES).content
        puts bsid
        puts @datafiles[dfid].inspect
        puts @bitstreams[bsid].inspect
        @datafiles[dfid].bitstream << @bitstreams[bsid]
        puts @bitstreams[bsid].inspect
      end
    end
  end

  def toDB
    Intentity.transaction do 
      
      #TODO: @int_entity.save  
      @formats.each { |fname, fmt| raise 'error saving format records'  unless fmt.save }
      # not necessary to explicitely save representations since representations will be saved through datafiles associations
      @datafiles.each {|dfid, df|  raise 'error saving datafile records' unless  df.save } 
      @bitstreams.each {|id, bs|  raise 'error saving bitstream records' unless bs.save }
      @agents.each {|id, ag|  raise 'error saving agent records' unless ag.save }
      @events.each {|id, e|  raise 'error saving event records' unless e.save }
      @relationships.each {|rel|  raise 'error saving relationship records' unless rel.save }
    end
    
  end

end