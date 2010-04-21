Agent_Types = { 
  "web service" => :software,
  "software" => :software
}

class Agent
  include DataMapper::Resource
  property :id, String, :key => true, :length => 255
  property :name, String, :length => 255
  property :type, Enum[:software, :person, :organization]
  property :note, Text
  # addition agent note which may include external tool information

  has 0..n, :events, :constraint => :destroy  # an agent can create 0-n int events.

  def fromPremis premis
    attribute_set(:id, premis.find_first("*:agentIdentifier/*:agentIdentifierValue", NAMESPACES).content)
    attribute_set(:name, premis.find_first("*:agentName", NAMESPACES).content)
    type = premis.find_first("*:agentType", NAMESPACES).content
    attribute_set(:type, Agent_Types[type.downcase])
    note = premis.find_first("*:agentNote", NAMESPACES)
    attribute_set(:note, note.content) if note
  end
end
