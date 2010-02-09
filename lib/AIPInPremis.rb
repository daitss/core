require 'xml'
require 'daitss2.rb'

class AIPInPremis
  def initialize 
    @int_entity = Intentity.new
    @representations = Array.new
    @datafiles = Hash.new
    @bitstreams = Hash.new
    @formats = Hash.new
    @events = Hash.new
    @agents = Hash.new
    @relationships = Array.new
  end

  def process aip_file
     # read in the posted AIP descriptor

     doc = XML::Document.file aip_file
     @int_entity.fromPremis
     
     # process all premis file objects
     fileObjects = doc.find("//premis:object[@xsi:type='file']", NAMESPACES)
     fileObjects.each do |obj|
       processDatafile obj
     end

     # extract all premis representations 
     repObjects = doc.find("//premis:object[@xsi:type='representation']", NAMESPACES)
     repObjects.each do |obj|
       processRepresentation obj    
     end

     # process all premis bitstreams 
     bitObjects = doc.find("//premis:object[@xsi:type='bitstream']", NAMESPACES)
     bitObjects.each do |obj|
       processBitstream obj    
     end

     # process all premis agents 
     agentObjects = doc.find("//premis:agent", NAMESPACES)
     agentObjects.each do |obj|
       processAgent obj
     end

     # process all premis events
     eventObjects = doc.find("//premis:event", NAMESPACES)
     eventObjects.each do |obj|
       processEvent obj
     end

     # process derived relationships associated with the file
     fileObjects = doc.find("//premis:object[@xsi:type='file']", NAMESPACES)
     fileObjects.each do |obj|
       dfid = obj.find_first("premis:objectIdentifier/premis:objectIdentifierValue", NAMESPACES).content
       relationships = obj.find("premis:relationship", NAMESPACES)
       relationships.each do |relationship|
         processRelationship(dfid, relationship)
       end
     end 

     toDB
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
    df.fromPremis(premis, @formats)

    @datafiles[df.id] = df
    
    # TODO need storage data model
    @mdtype = premis.find_first("premis:objectCharacteristics/premis:fixity/premis:messageDigestAlgorithm", NAMESPACES).content
    @mdvalue = premis.find_first("premis:objectCharacteristics/premis:fixity/premis:messageDigest", NAMESPACES).content
  end

  def processBitstream premis
    bs = Bitstream.new
    bs.fromPremis(premis, @formats)

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
  
  def processRelationship(dfid, relationship_element)
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
        # bsid
        @datafiles[dfid].bitstreams << @bitstreams[bsid]
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
