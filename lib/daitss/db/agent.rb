require 'data_mapper'

Agent_Types = ["software", "person", "organization"]
Agent_Map = {
  "web service" => "software",
  "software" => "software",
  "affiliate" => "organization"
}

class Agent
  include DataMapper::Resource
  property :id, String, :key => true, :length => 255
  property :name, String, :length => 255
  property :type, String, :length => 20, :required => true
  validates_with_method :type, :method => :validateType
  property :note, Text # additional agent note which may include external tool information

  has 0..n, :events, :constraint => :destroy  # an agent can create 0-n events.

  # validate the agent type value which is a daitss defined controlled vocabulary
  def validateType
    if Agent_Types.include?(@type)
      return true
    else
      [ false, "value #{@type} is not a valid agent type value" ]
    end
  end

  def fromPremis premis
    attribute_set(:id, premis.find_first("premis:agentIdentifier/premis:agentIdentifierValue", NAMESPACES).content)
    attribute_set(:name, premis.find_first("premis:agentName", NAMESPACES).content)
    type = premis.find_first("premis:agentType", NAMESPACES).content
    attribute_set(:type, Agent_Map[type.downcase])
    note = premis.find_first("*[local-name()='agentNote']", NAMESPACES)
    attribute_set(:note, note.content) if note
  end
end
