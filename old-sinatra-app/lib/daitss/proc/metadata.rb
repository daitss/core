require 'daitss/proc/wip'
require 'daitss/proc/datafile'

module Daitss

  # Common metadata functionality between Wip and DataFile
  module Metadata

    # Return metadata values for the specified keys
    def metadata_for *keys
      new_md_keys = keys.select { |key| metadata.has_key? key }
      new_digiprov = new_md_keys.map { |key| metadata[key] }
    end

    # based on the presence of old events determine the next event index
    def next_event_index event_type

      es = old_events.select { |event| event.find("/P:event/P:eventType = '#{event_type}'", NS_PREFIX) }

      if es.empty?
        "0"
      else

        ids = es.map do |e|
          xpath = "/P:event/P:eventIdentifier/P:eventIdentifierValue"
          uri = e.find_first(xpath, NS_PREFIX).content
          uri[%r{/(\d+)$},1].to_i
        end

        (ids .max + 1).to_s
      end

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

end
