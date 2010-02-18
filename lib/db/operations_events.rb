require 'dm-core'
require 'db/operations_agents'

# TODO: this needs to have an association the the Intentity table, not a string for IEID

class OperationsEvent 
  include DataMapper::Resource

  property :id, Serial
  property :timestamp, DateTime, :nullable => false
  property :event_name, String, :nullable => false
  property :notes, Text
  property :ieid, String, :nullable => false
  
  belongs_to :operations_agent
end
