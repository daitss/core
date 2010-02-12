Event_Types = { 
  "Ingest" => :ingest,
  "Submit" => :submit,
  "Validate" => :validate,
  "Dissemination" => :disseminate,
  "Withdraw" => :withdraw,
  "Fixity Check" => :fixitycheck,
  "Format Description" => :describe,
  "Normalization" => :normalize, 
  "Migration" => :migrate }

  class Event
    include DataMapper::Resource
    property :id, String, :key => true, :length => 16
    property :idType, String # identifier type
    property :e_type, Enum[:submit, :validate, :ingest, :disseminate, :withdraw, :fixitycheck, :describe, :migrate, :normalize, :deletion]
    property :datetime, DateTime
    property :outcome, String  # ex. sucess, failed.  TODO:change to Enum.
    property :outcome_details, String, :length => 255  # additional information about the event outcome.
    property :relatedObjectId, String # the identifier of the related object.
    # if object A migrated to object B, the object B will be associated with a migrated_from event
    property :class, Discriminator
    belongs_to :agent
    # an event must be associated with an agent
    # note: for deletion event, the agent would be reingest.

    def setRelatedObject objid
      attribute_set(:relatedObjectId, objid)
    end 

    def fromPremis(premis)
      attribute_set(:id, premis.find_first("premis:eventIdentifier/premis:eventIdentifierValue", NAMESPACES).content)
      attribute_set(:idType, premis.find_first("premis:eventIdentifier/premis:eventIdentifierType", NAMESPACES).content)
      type = premis.find_first("premis:eventType", NAMESPACES).content
      attribute_set(:e_type, Event_Types[type])
      attribute_set(:datetime, premis.find_first("premis:eventDateTime", NAMESPACES).content)
      attribute_set(:outcome, premis.find_first("premis:eventOutcomeInformation/premis:eventOutcome", NAMESPACES).content)
    end

  end
  class IntentityEvent < Event
    before :save do
      #TODO implement validation of objectID, making sure the objectID is a valid IntEntity
    end
  end

  class RepresentationEvent < Event
    before :save do
      #TODO implement validation of objectID, making sure the objectID is a valid representation
    end
  end

  class DatafileEvent < Event  
    def fromPremis(premis, df)
      super(premis)
      details = premis.find_first("premis:eventOutcomeInformation/premis:eventOutcomeDetail", NAMESPACES)
      unless details.nil?
        detailsExtension = premis.find_first("premis:eventOutcomeInformation/premis:eventOutcomeDetail/premis:eventOutcomeDetailExtension", NAMESPACES)
        if detailsExtension.nil?
          attribute_set(:outcome_details, details.content.strip!) 
        else
          puts detailsExtension
          @anomalies = Array.new
          anomalies = detailsExtension.find("//premis:anomaly", NAMESPACES)
          anomalies.each do |obj|
            anomaly = Anomaly.new
            anomaly.fromPremis(obj)
            df.severe_element << anomaly
          end
        end
      end
    end
    
    before :save do
      #TODO implement validation of objectID, making sure the objectID is a valid datafile
    end
  end
