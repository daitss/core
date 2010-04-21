require 'xml'
require 'daitss2.rb'
require 'ruby-prof'

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
  def process aipxml
    @doc = aipxml

    # create an new intentities or locate the existing int entities for the int entity object in the aip descriptior.  
    processIntEntity

    # find the agreement for the int entity
    processAgreement

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

  def processIntEntity
    @int_entity = Intentity.new
    @int_entity.fromAIP @doc
    # check if this is an existing int entity, if not create a new int entity object with 
    # the read-in premis info.  Otheriwse, destroy the existing int entity records in the database 
    # including all related datafiles, representations, events and agents. 
    entities = Intentity.all(:id => @int_entity.id)  
    entities.each do |entity|
      # start database traction for deleting the associated record for the aip.  If there is any failure during database save, 
      # datamapper automatically rollback the change.
      Intentity.transaction do
        # destroy all files in the int entities 
        files = Hash.new
        representations = Representation.all(:intentity_id => entity.id)
        representations.each do |rep| 
          dfreps = DatafileRepresentation.all(:representation_id => rep.id)
          dfreps.each do |dfrep|
            dfs = Datafile.all(:id => dfrep.datafile_id)
            dfs.each do |df| 
              # remove all events and relationship associated with this datafile
              files[df.id] = df 
            end
          end
        end

        files.each do |id,df| 
          raise "error deleting datafile #{df.inspect}" unless df.destroy
        end

        raise "error deleting entity #{entity.inspect}" unless entity.destroy
      end
    end
  end

  def processAgreement
    # retrieve agreement info.
    agreement = @doc.find_first("//mets:digiprovMD[@ID = 'AGREEMENT-INFO']/mets:mdWrap/mets:xmlData/daitss:AGREEMENT_INFO", NAMESPACES)
    if agreement
      account = agreement.find_first("@ACCOUNT", NAMESPACES).value
      project = agreement.find_first("@PROJECT", NAMESPACES).value
      acct = Account.first(:code => account)
      acctProjects = Project.all(:code => project) & Project.all(:account => acct)
      raise "cannot find the project recrod for #{account}, #{project} " if acctProjects.empty?
      @acctProject = acctProjects.first
      @acctProject.intentities << @int_entity
    else
      raise "no agreement info specified in the aip descriptor"
    end
  end

  # extract representation information from the premis document
  def processRepresentations
    r0 = Array.new
    rc = Array.new
    rn = Array.new

    repObjects = @doc.find("//premis:object[@xsi:type='representation']", NAMESPACES)
    repObjects.each do |obj|
      rep = Representation.new
      rep.fromPremis obj

      files = obj.find("premis:relationship", NAMESPACES)
      files.each do |f|
        dfid = f.find_first("premis:relatedObjectIdentification/premis:relatedObjectIdentifierValue", NAMESPACES).content
        df = @datafiles[dfid]
        unless df.nil?
          dfrep = DatafileRepresentation.new
          df.datafile_representation << dfrep
          rep.datafile_representation << dfrep
          if rep.isR0
            r0 << dfid
          elsif rep.isRC
            rc << dfid
          elsif rep.isRN
            rn << dfid
          end
        end
      end

      @int_entity.representations << rep
    end

    # set the origin of all datafiles by deriving the origin information from their associations with representations
    @datafiles.each do |dfid, df|
      df.setOrigin r0, rc, rn
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
    agentObjects = @doc.find("//*[ local-name() = 'agent' ]", NAMESPACES)
    agentObjects.each do |obj|
      agent = Agent.new
      agent.fromPremis obj

      # use the existing agent record in the database if we have seen this agent before
      existingAgent = Agent.get(agent.id)
      if existingAgent
        @agents[agent.id] = existingAgent
      else
        @agents[agent.id] = agent
      end
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

      if df   #first check if this event is linked to a file object
        event = DatafileEvent.new
        event.fromPremis(obj, df, @anomalies)
        event.setRelatedObject id.content
        # associate agent to the event
        agent.events << event unless agent.nil?
        @events[event.id] = event
      elsif id && @int_entity.match(id.content) #then check if this event links to int entity
        event = IntentityEvent.new
        event.fromPremis(obj)
        event.setRelatedObject id.content
        # associate agent to the event
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
        @datafiles[dfid].bitstreams << @bitstreams[bsid] if @bitstreams[bsid]
      end
    end
  end

  # save all extracted premis objects/events/agents to the fast access database in one transaction
  def toDB
    repository(:default) do 
      # start database traction for saving the associated record for the aip.  If there is any failure during database save, 
      # datamapper automatically rollback the change.
      Intentity.transaction do 
        # RubyProf.start  
        @int_entity.save  
        @acctProject.save
        # not necessary to explicitely save representations since representations will be saved through intentity associations        
        # @formats.each { |fname, fmt| raise 'error saving format records'  unless fmt.save }
        @datafiles.each {|dfid, df|  raise 'error saving datafile records' unless  df.save } 
        # @bitstreams.each {|id, bs|  raise 'error saving bitstream records' unless bs.save }
        @events.each {|id, e|  raise 'error saving event records' unless e.save }
        @relationships.each {|rel|  raise 'error saving relationship records' unless rel.save }
        # r = RubyProf.stop
        # printer = RubyProf::GraphHtmlPrinter.new r
        # open('/Users/Carol/Workspace/database/profile.html', 'w') { |io| printer.print io, :min_percent=> 0 }
      end
    end
  end

end
