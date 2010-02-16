require 'dm-core'
require 'db/operations_agents'

class Key
  include DataMapper::Resource

  property :id, Serial
  property :key, Text

  has 1, :operations_agent
end
