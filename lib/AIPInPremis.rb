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

  # process an aip descriptor described in a premis-in-mets format.
  def process aip_file
    # read in the AIP descriptor
    @doc = XML::Document.file aip_file
    @int_entity.fromPremis

    # process all premis file objects
    processDatafiles

    # extract all premis representations 
    processRepresentations    

    # process all premis bitstreams 
    processBitstreams

    # process all premis agents 
    processAgents

    # process all premis events
    processEvents

    # process derived relationships associated with the files
    fileObjects = @doc.find("//premis:object[@xsi:type='file']", NAMESPACES)
    fileObjects.each do |obj|
      dfid = obj.find_first("premis:objectIdentifier/premis:objectIdentifierValue", NAMESPACES).content
      relationships = obj.find("premis:relationship", NAMESPACES)
      relationships.each do |relationship|
        processRelationship(dfid, relationship)
      end
    end 

    toDB
  end

  # extract representation information from the premis document
  def processRepresentations
    r0 = Array.new
    rc = Array.new

    repObjects = @doc.find("//premis:object[@xsi:type='representation']", NAMESPACES)
    repObjects.each do |obj|
      rep = Representation.new
      rep.fromPremis obj

      files = obj.find("premis:relationship", NAMESPACES)
      files.each do |f|
        dfid = f.find_first("premis:relatedObjectIdentification/premis:relatedObjectIdentifierValue", NAMESPACES).content
        df = @datafiles[dfid]
        unless df.nil?
          df.representations << rep
          if rep.isR0
            r0 << dfid
          elsif rep.isRC
            rc << dfid
          end
        end
      end

      @int_entity.representations << rep
      @representations << rep
    end

    # set the origin of all datafiles by deriving the origin information from their associations with representations
    @datafiles.each do |dfid, df|
      df.setOrigin r0, rc
    end
  end

  # extract all file objects from the premis document
  def processDatafiles
    fileObjects = @doc.find("//premis:object[@xsi:type='file']", NAMESPACES)

    fileObjects.each do |obj|
      df = Datafile.new
      df.fromPremis(obj, @formats)

      @datafiles[df.id] = df
    end
  end

  # extract alll bitstream objects from the premis document
  def processBitstreams
    bitObjects = @doc.find("//premis:object[@xsi:type='bitstream']", NAMESPACES)
    bitObjects.each do |obj|
      bs = Bitstream.new
      bs.fromPremis(obj, @formats)
      @bitstreams[bs.id] = bs 
    end
  end

  # extract all agents in the premis document
  def processAgents
    agentObjects = @doc.find("//premis:agent", NAMESPACES)
    agentObjects.each do |obj|
      agent = Agent.new
      agent.fromPremis obj
      # only create a new agent record if the agent has NOT been seen before
      @agents[agent.id] = agent if (Agent.first(:id => agent.id).nil?)
    end
  end

  # extract all events from the premis document
  def processEvents
    eventObjects = @doc.find("//premis:event", NAMESPACES)
    eventObjects.each do |obj|
      id = obj.find_first("premis:linkingObjectIdentifier/premis:linkingObjectIdentifierValue", NAMESPACES)
      # make sure this event related to a datafile
      df = @datafiles[id.content] unless id.nil?

      agent_id = obj.find_first("premis:linkingAgentIdentifier/premis:linkingAgentIdentifierValue", NAMESPACES)
      agent = @agents[agent_id.content] unless agent_id.nil?   

      unless df.nil?
        event = DatafileEvent.new
        event.fromPremis(obj, df)
        event.setRelatedObject id.content
        #associate agent to the event
        agent.events << event unless agent.nil?
        @events[event.id] = event
      end
    end
  end

  # extract and construct premis relationship among objects
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
        @datafiles[dfid].bitstreams << @bitstreams[bsid]
      end
    end
  end

  # save all extracted premis objects/events/agents to the fast access database in one transaction
  def toDB
    repository(:default) do 
      # start database traction for saving the associated record for the aip.  If there is any failure during database save, 
      # datamapper automatically rollback the change.
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

end
