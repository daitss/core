require 'xml'

require 'daitss/db'
#require 'memory_debug'

module Daitss
  XMLRES ='<eventType>XML Resolution</eventType>'

  class AIPInPremis

    def initialize
      @datafiles = Hash.new
      @bitstreams = Hash.new
      @formats = Hash.new
      @anomalies = Hash.new
      @inhibitors = Hash.new
      @events = Hash.new
      @agents = Hash.new
      @relationships = Array.new
    end

    # process an aip descriptor described in a premis-in-mets format.
    def processAIPFile aip_file
      # read in the AIP descriptor
      process XML::Document.file aip_file
    end

    # process an aip descriptor described in a premis-in-mets format.
    def process package, aipxml
      @package = package
      @doc = aipxml
      
      # create an new intentities or locate the existing int entities for the int entity object in the aip descriptior.
      processIntEntity
      
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
        processRelationship(dfid, obj)
      end
    end

    def processIntEntity
      @int_entity = Intentity.new
      @int_entity.fromAIP @doc
      # check if this is an existing int entity, if not create a new int entity object with
      # the read-in premis info.  Otheriwse, destroy the existing int entity records in the database
      # including all related datafiles, representations, events and agents.
      entity = Intentity.first(:id => @int_entity.id)
      if (entity)
        entity.deleteChildren
        # those the destroy! bypass the datamapper validation, it will still delete the associated children
        # dependencies.  Tables that are not associated directly such as image/documents/texts/audios/object_formats
        # will be cascade deleted when the datafile is deleted.
        entity.destroy!
      end
  
      @package.intentity = @int_entity
    end

    # extract representation information from the premis document
    def processRepresentations
      repObjects = @doc.find("//premis:object[@xsi:type='representation']", NAMESPACES)
      repObjects.each do |obj|
        rep_id = obj.find_first("premis:objectIdentifier/premis:objectIdentifierValue", NAMESPACES).content
        files = obj.find("premis:relationship", NAMESPACES)
        files.each do |f|
          dfid = f.find_first("premis:relatedObjectIdentification/premis:relatedObjectIdentifierValue", NAMESPACES).content
          df = @datafiles[dfid]
          df.setRepresentations(rep_id)  unless df.nil?
        end

      end

      # set the origin of all datafiles by deriving the origin information from their associations with representations
      @datafiles.each do |dfid, df|
        df.setOrigin
      end
    end

    # extract all file objects from the premis document
    def processDatafiles
      sip_descriptor_node = @doc.find_first("//M:file[@USE='sip descriptor']", NS_PREFIX)
      sip_descriptor_ownerid = sip_descriptor_node['OWNERID'] if sip_descriptor_node
      fileObjects = @doc.find("//premis:object[@xsi:type='file']", NAMESPACES)
      
      obsolete_dfs = @doc.find("//mets:file[not(mets:FLocat)]", NAMESPACES).map { |n| n['OWNERID'] }.to_set
      
      fileObjects.each do |obj| 
        df = Datafile.new
        #GC.start
        #delta_stats
        
        df.fromPremis(obj, @formats, sip_descriptor_ownerid)
        unless obsolete_dfs.include? df.id
          @datafiles[df.id] = df
          @int_entity.datafiles << df
        end

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
        agent = PremisAgent.new
        agent.fromPremis obj

        # use the existing agent record in the database if we have seen this agent before
        existingAgent = PremisAgent.get(agent.id)
        if existingAgent
          @agents[agent.id] = existingAgent
        else
          @agents[agent.id] = agent
        end
      end
    end

    # extract all events from the premis document, but only the first XMLRES events
    def processEvents
      eventObjects = @doc.find("//premis:event", NAMESPACES).to_a
      xmlresFirstEvents = Array.new
      eventObjects.each_with_index do |obj,i|
	      id = obj.find_first("premis:linkingObjectIdentifier/premis:linkingObjectIdentifierValue", NAMESPACES).to_s
	      type = obj.find_first("premis:eventType", NAMESPACES)
	      if type.to_s == XMLRES    && xmlresFirstEvents.index(id+XMLRES) 
		      eventObjects.delete_at(i)
	      else
		      xmlresFirstEvents << id + type.to_s 
	      end
      end
      eventObjects.each do |obj|
        id = obj.find_first("premis:linkingObjectIdentifier/premis:linkingObjectIdentifierValue", NAMESPACES)
        # make sure this event related to a datafile
        df = @datafiles[id.content] unless id.nil?

        agent_id = obj.find_first("premis:linkingAgentIdentifier/premis:linkingAgentIdentifierValue", NAMESPACES)
        agent = @agents[agent_id.content] unless agent_id.nil?

        if df  #first check if this event is linked to a file object
          event = DatafileEvent.new
          event.fromPremis(obj, df, @anomalies)
          event.setRelatedObject id.content
          # associate agent to the event
          agent.premis_events << event unless agent.nil?
          @events[event.id] = event
        elsif id && @int_entity.match(id.content) #then check if this event links to int entity
          event = IntentityEvent.new
          event.fromPremis(obj)
          event.setRelatedObject id.content
          # associate agent to the event
          agent.premis_events << event unless agent.nil?
          @events[event.id] = event
        end
      end
    end

    # extract and construct premis relationship among objects
    def processRelationship(dfid, file_obj)
      unless (@datafiles[dfid].nil?)
        d_relationships = file_obj.find("premis:relationship[premis:relationshipType = 'derivation' and premis:relationshipSubType = 'has source']", NAMESPACES)
        s_relationships = file_obj.find("premis:relationship[premis:relationshipType = 'structural' and premis:relationshipSubType = 'includes']", NAMESPACES)

        d_relationships.each do |relationship|
          event_id = relationship.find_first("premis:relatedEventIdentification/premis:relatedEventIdentifierValue", NAMESPACES)
          event = @events[event_id.content] unless event_id.nil?
          unless (event.nil?)
            relationshipObj = Relationship.new
            relationshipObj.fromPremis(dfid, event.e_type, relationship)
            @relationships << relationshipObj
          end
        end

        s_relationships.each do |relationship|
          bsid = relationship.find_first("premis:relatedObjectIdentification/premis:relatedObjectIdentifierValue", NAMESPACES).content
          @datafiles[dfid].bitstreams << @bitstreams[bsid] if @bitstreams[bsid]
        end
      end
    end

    # save all extracted premis objects/events/agents to the fast access database in one transaction
    def toDB
      # @datafiles.each {|dfid, df| df.check_errors unless  df.save }
      unless @int_entity.save!
        @int_entity.check_errors 
        raise "error in saving int entity, no validation error found"
      end

      unless @package.save!
        raise "error in saving package #{@package}"
      end
      
      # explicitly saving the dependencies.
      @events.each {|id, e| raise "error saving event records #{e.inspect}" unless e.save! }
      @relationships.each {|rel|  raise 'error saving relationship records' unless rel.save! }
    end
  end

end
