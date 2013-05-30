require 'daitss/proc/template/descriptor'
require 'daitss/proc/template/premis'
require 'daitss/proc/wip/from_aip'
require 'daitss/proc/wip/preserve'
require 'daitss/proc/wip/tarball'
require 'daitss/proc/wip/to_aip'
require 'daitss/proc/xmlvalidation'

module Daitss

  class Wip

    def refresh
      load_from_aip
      preserve
          
      step 'refresh digiprov'  do
        metadata['refresh-event'] = refresh_event package, next_event_index('refresh')
        metadata['refresh-agent'] = system_agent
      end

      step('make aip descriptor') { make_aip_descriptor }
      step('validate aip descriptor') { validate_aip_descriptor }
      step('make tarball') { make_tarball }
      step('make aip') { update_aip }
      step('delete old copy') { delete_old_aip }
    end
  end
end
