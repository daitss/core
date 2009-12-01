class Agent
  include DataMapper::Resource
  property :id, String, :key => true
  property :name, String
  property :type, Enum[:software, :person, :organization]
  
  has 0..n, :events # an agent can create 0-n int events.
end
