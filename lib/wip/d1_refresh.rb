require 'proc/template/descriptor'
require 'proc/template/premis'
require 'proc/wip'
require 'proc/wip/from_d1'
require 'proc/wip/journal'
require 'proc/wip/preserve'
require 'proc/wip/to_aip'

class Wip

  def d1refresh
    raise "no aip for #{id}" unless package.aip

    #TODO handle withdrawn packages
    step('load-aip') { load_from_d1_aip }

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
  end

end
