require 'daitss/proc/template'
require 'daitss/proc/wip'

module Daitss

  class Wip

    DMD_KEYS = ['dmd-issue', 'dmd-volume', 'dmd-title', 'dmd-entity-id']

    def has_dmd?

      DMD_KEYS.any? do |dmd_key|
        metadata.keys.include? dmd_key
      end

    end

    def dmd
      template_by_name('aip/dmd').result binding
    end

  end

end
