require 'dm-core'
require 'db/operations_agents'

class Key
  include DataMapper::Resource

  property :id, Serial
  property :key, Text

  belongs_to :operations_agent
end
