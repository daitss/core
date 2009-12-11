Agent_Types = { 
  "Web Service" => :software
}

class Agent
  include DataMapper::Resource
  property :id, String, :key => true
  property :name, String
  property :type, Enum[:software, :person, :organization]
  
  has 0..n, :events # an agent can create 0-n int events.
  
  def fromPremis premis
     attribute_set(:id, premis.find_first("premis:agentIdentifier/premis:agentIdentifierValue", NAMESPACES).content)
     attribute_set(:name, premis.find_first("premis:agentName", NAMESPACES).content)
     type = premis.find_first("premis:agentType", NAMESPACES).content
     attribute_set(:type, Agent_Types[type])
   end
end
