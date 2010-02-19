require 'dm-core'
require 'db/operations_events'

# adds a new package tracker event.
# raises exception if provided agent_identifier does not correspond to a valid agent
# TODO: raise exception if provided ieid does not correspond to a valid ieid
class PackageTracker
  def self.insert_op_event agent_identifier, ieid, event_name, message
    agent = OperationsAgent.first(:identifier => agent_identifier)

    raise "Specified operations agent does not exist" unless agent
    raise "No event name specified" unless event_name and event_name != ""

    event = agent.operations_events.new(:timestamp => Time.now,
                                        :event_name => event_name,
                                        :notes => message,
                                        :ieid => ieid )

    event.save
  end

  def self.query_op_event agent_identifier = :any, ieid = :any, event_name = :any, timestamp_upper_bound = 0, timestamp_lower_bound = 0
  end
end
