require 'dm-core'
require 'db/operations_agents'

# TODO: this should probably have an association the the Intentity table, not a string for IEID

class OperationsEvent 
  include DataMapper::Resource

  property :id, Serial, :key => true
  property :timestamp, DateTime, :required => true
  property :event_name, String, :required => true
  property :notes, Text
  
  belongs_to :operations_agent
  belongs_to :submitted_sip
end
