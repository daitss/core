require 'daitss/proc/datafile'
require 'daitss/proc/metadata'

module Daitss

  class DataFile

    def obsolete!
      raise "#{self} is already obsolete" if obsolete?

      a_spec = {
        :id => "info:fda/daitss",
        :name => 'daitss processing',
        :type => 'software'
      }

      e_spec = {
        :id => "#{uri}/event/obsolete",
        :type => 'obsolete',
        :linking_objects => [uri],
        :linking_agents => [a_spec[:id]]
      }

      metadata['obsolete-event'] = event e_spec
      metadata['obsolete-agent'] = agent a_spec
    end

    def obsolete?

      metadata.has_key?('obsolete-event') or old_events.any? do |doc|
        doc.find "//P:eventType = 'obsolete'", NS_PREFIX
      end

    end

  end

end
