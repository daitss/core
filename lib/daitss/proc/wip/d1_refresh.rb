require 'daitss/proc/template/descriptor'
require 'daitss/proc/template/premis'
require 'daitss/proc/wip'
require 'daitss/proc/wip/from_d1'
require 'daitss/proc/wip/journal'
require 'daitss/proc/wip/preserve'
require 'daitss/proc/wip/to_aip'

module Daitss

  class Wip

    def d1refresh
      raise "no aip for #{id}" unless package.aip

      load_from_d1_aip

      preserve

      step('write-d1migrate-event') do
        metadata['d1migrate-event'] = d1migrate_event package, next_event_index('d1migrate')
      end

      step('write-d1migrate-agent') do
        metadata['d1migrate-agent'] = system_agent
      end

      step('make aip descriptor') { make_aip_descriptor }
      step('validate aip descriptor') { validate_aip_descriptor }
      step('make tarball') { make_tarball }
      step('make aip') { update_aip }
      step('delete old copy') { delete_old_aip }
    end

  end

end
