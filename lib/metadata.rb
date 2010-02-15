require 'wip'
require 'datafile'

# Common metadata functionality between Wip and DataFile
module Metadata

  # Return metadata values for the specified keys
  def metadata_for *keys
    new_md_keys = keys.select { |key| metadata.has_key? key }
    new_digiprov = new_md_keys.map { |key| metadata[key] } 
  end

  # Return an array of old events
  def old_events

    if metadata.has_key? 'old-digiprov-events'
      raw_events = metadata['old-digiprov-events'].split %r{\n(?=<event)}
      raw_events.map { |s| XML::Document.string s }
    else
      []
    end

  end

  # Return an array of old agents
  def old_agents

    if metadata.has_key? 'old-digiprov-agents'
      raw_agents = metadata['old-digiprov-agents'].split %r{\n(?=<agent)}
      raw_agents.map { |s| XML::Document.string s }
    else
      []
    end

  end

end

class Wip
  include Metadata
end

class DataFile
  include Metadata
end
