require 'dm-core'
require 'db/operations_agents'
require 'db/int_entity'

class OperationsEvents 
  include DataMapper::Resource

  property :id, Serial
  property :timestamp, DateTime, :nullable => false
  property :event_name, String, :nullable => false
  property :notes, Text
  
  belongs_to :operations_agent
  belongs_to :intentity
end
