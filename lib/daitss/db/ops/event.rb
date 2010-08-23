require 'dm-core'

require 'daitss/db/ops/sip'
require 'daitss/db/ops/agent'

# TODO: this should probably have an association the the Intentity table, not a string for IEID

class OperationsEvent
  include DataMapper::Resource

  property :id, Serial, :key => true
  property :timestamp, DateTime, :required => true
  property :event_name, String, :required => true
  property :notes, Text

  belongs_to :operations_agent
  belongs_to :sip
end

class Wip

  def log_op_event name, notes=nil
    ss = Sip.first :id => self.id
    e = OperationsEvent.new
    e.event_name = name
    e.notes = notes if notes
    e.timestamp = Time.now
    e.operations_agent = Program.system_agent
    e.sip = ss
    e.save or raise "cannot save op event: #{name}"
  end

end
