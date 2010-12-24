require 'daitss/proc/template/premis'

module Daitss

  # constant for event types
  INGEST = "ingest"
  SUBMIT = "submit"
  VALIDATE = "validate"
  VIRUS_CHECK = "virus check"
  DISSEMINATE = "disseminate"
  D1REFRESH = "d1refresh"
  REDUP = "redup"
  WITHDRAW = "withdraw"
  FIXITY_CHECK = "fixitycheck"
  DESCRIBE = "describe"
  NORMALIZE = "normalize"
  MIGRATE = "migrate"
  XML_RESOLUTION = "xml resolution"
  DELETION = "deletion"
  BROKEN_LINKS = "broken links found"

  # all possible event types
  Event_Type = [INGEST, SUBMIT, VALIDATE, VIRUS_CHECK, DISSEMINATE, D1REFRESH, REDUP,
    WITHDRAW, FIXITY_CHECK, DESCRIBE, NORMALIZE, MIGRATE, XML_RESOLUTION, DELETION, BROKEN_LINKS]

  Event_Map = {
    "ingest" => INGEST,
    "submit" => SUBMIT,
    "comprehensive validation" => VALIDATE,
    "virus check" => VIRUS_CHECK,
    "disseminate" => DISSEMINATE,
    "d1refresh" => D1REFRESH,
    "redup" => REDUP,
    "withdraw" => WITHDRAW,
    "fixity Check" => FIXITY_CHECK,
    "describe" => DESCRIBE,
    "normalize" => NORMALIZE,
    "migration" => MIGRATE,
    "xml resolution" => XML_RESOLUTION,
    "broken links found" => BROKEN_LINKS,
  }

  class PremisEvent
    include DataMapper::Resource
    property :id, String, :key => true, :length => 100
    property :idType, String # identifier type
    property :e_type, String, :length => 20, :required => true
    validates_with_method :e_type, :method => :validateEventType
    property :datetime, DateTime
    property :event_detail, String, :length => 255 # event detail
    property :outcome, String, :length => 255   # ex. sucess, failed.  TODO:change to Enum.
    property :outcome_details, Text, :length => 2**32-1 # additional information about the event outcome.
    property :relatedObjectId, String , :length => 100 # the identifier of the related object.
    # if object A migrated to object B, the object B will be associated with a migrated_from event
    property :class, Discriminator
    belongs_to :premis_agent
    # an event must be associated with an agent
    # note: for deletion event, the agent would be reingest.

    # datamapper return system error once this constraint is added in.  so we will delete relationship manually
    # has 0..n, :relationships, :constraint=>:destroy

    # validate the event type value which is a daitss defined controlled vocabulary
    def validateEventType
      if Event_Type.include?(@e_type)
        return true
      else
        [ false, "value #{@e_type} is not a valid event type value" ]
      end
    end

    # set related object id which could either be a datafile or an intentity object
    def setRelatedObject objid
      attribute_set(:relatedObjectId, objid)
    end

    def fromPremis(premis)
      attribute_set(:id, premis.find_first("premis:eventIdentifier/premis:eventIdentifierValue", NAMESPACES).content)
      attribute_set(:idType, premis.find_first("premis:eventIdentifier/premis:eventIdentifierType", NAMESPACES).content)
      type = premis.find_first("premis:eventType", NAMESPACES).content
      attribute_set(:e_type, Event_Map[type.downcase])
      eventDetail = premis.find_first("premis:eventDetail", NAMESPACES)
      attribute_set(:event_detail, eventDetail.content) if eventDetail
      attribute_set(:datetime, premis.find_first("premis:eventDateTime", NAMESPACES).content)
      attribute_set(:outcome, premis.find_first("premis:eventOutcomeInformation/premis:eventOutcome", NAMESPACES).content)
    end

    def to_premis_xml
       event :id => self.id, :type => self.e_type, :time => self.datetime, :outcome => self.outcome, :linking_agents => [self.premis_agent.id], :linking_objects => [self.relatedObjectId]
     end

    before :save do
      puts "#{self.errors.to_a} error encountered while saving #{self.inspect} " unless valid?
      puts "#{self.premis_agent.errors.to_a} error encountered while saving #{self.premis_agent.inspect} " unless self.premis_agent.valid?
    end
  end

  class IntentityEvent < PremisEvent
    before :save do
      #TODO implement validation of objectID, making sure the objectID is a valid IntEntity
    end
  end

  class RepresentationEvent < PremisEvent
    before :save do
      #TODO implement validation of objectID, making sure the objectID is a valid representation
    end
  end

  class DatafileEvent < PremisEvent
    attr_reader :df
    attr_reader :anomalies

    def fromPremis(premis, df, anomalies)
      super(premis)
      details = premis.find_first("premis:eventOutcomeInformation/premis:eventOutcomeDetail", NAMESPACES)
      if details
        detailsExtension = details.find_first("premis:eventOutcomeDetailExtension", NAMESPACES)
        attribute_set(:outcome_details, details.content.strip!) if detailsExtension.nil?
        unless detailsExtension.nil?
          @df = df
          @anomalies = anomalies
          nodes = detailsExtension.find("premis:anomaly", NAMESPACES)
          processAnomalies(nodes)
          nodes = detailsExtension.find("premis:broken_link", NAMESPACES)
          unless (nodes.empty?)
            brokenlink = BrokenLink.new
            brokenlink.fromPremis(@df, detailsExtension)
          end
        end
      end
    end

    def processAnomalies(nodes)
      nodes.each do |obj|
        anomaly = Anomaly.new
        anomaly.fromPremis(obj)

        # check if it was processed earlier.
        existinganomaly = @anomalies[anomaly.name]

        # if it's has not processed earlier, use the existing anomaly record
        # in the database if we have seen this anomaly before
        existinganomaly = Anomaly.first(:name => anomaly.name) if existinganomaly.nil?
        dfse = DatafileSevereElement.new
        @df.datafile_severe_element << dfse
        if existinganomaly
          existinganomaly.datafile_severe_element << dfse
        else
          anomaly.datafile_severe_element << dfse
          @anomalies[anomaly.name] = anomaly
        end
      end
    end

    before :save do
      #TODO implement validation of objectID, making sure the objectID is a valid datafile
    end

  end

end
