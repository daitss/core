Event_Types = { 
  "Format Description" => :describe
}

class Event
  include DataMapper::Resource
  property :id, String, :key => true, :length => 16
  property :idType, String # identifier type
  property :type, Enum[:submit, :validate, :ingest, :disseminate, :withdraw, :fixitycheck, :describe, :migrate_from, :normalize_from, :deletion]
  property :datetime, DateTime
  property :details, String # additional detail information about the event
  property :outcome, String  # ex. sucess, failed.  TODO:change to Enum.
  property :outcome_details, String  # additional information about the event outcome.
  # property :relatedObjectType, String # the type of the related object, ex. intentity
  property :relatedObjectId, String # the identifier of the related object.
  # if object A migrated to object B, the object B will be associated with a migrated_from event
  property :class, Discriminator
  belongs_to :agent
  # an event must be associated with an agent
  # note: for deletion event, the agent would be reingest.

  def setRelatedObject objid
    attribute_set(:relatedObjectId, objid)
  end 

  def fromPremis premis
    attribute_set(:id, premis.find_first("premis:eventIdentifier/premis:eventIdentifierValue", NAMESPACES).content)
    attribute_set(:idType, premis.find_first("premis:eventIdentifier/premis:eventIdentifierType", NAMESPACES).content)
    type = premis.find_first("premis:eventType", NAMESPACES).content
    attribute_set(:type, Event_Types[type])
    attribute_set(:datetime, premis.find_first("premis:eventDateTime", NAMESPACES).content)
    attribute_set(:outcome, premis.find_first("premis:eventOutcomeInformation/premis:eventOutcome", NAMESPACES).content)
    details = premis.find_first("premis:eventOutcomeInformation/premis:eventOutcomeDetail", NAMESPACES)
    attribute_set(:outcome_details, details.content) unless details.nil?
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
  before :save do
    #TODO implement validation of objectID, making sure the objectID is a valid datafile
  end
end
