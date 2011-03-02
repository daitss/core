require 'dm-transactions'

require 'service/virus'
require 'proc/template/descriptor'
require 'proc/template/premis'
require 'proc/wip/preserve'
require 'proc/wip/tarball'
require 'proc/wip/to_aip'
require 'xmlvalidation'

class Wip

  def ingest

    original_datafiles.each do |df|

      step("virus check #{df.id}") do
        vc = Virus.new df.data_file, df.uri
        vc.post
        df.metadata['virus-check-event'] = vc.event
        df.metadata['virus-check-agent'] = vc.agent
        raise "virus detected\n#{vc.note}" if vc.failed?
      end

    end

    preserve

    step('ingest digiprov') do
      metadata['ingest-event'] = ingest_event package
      metadata['ingest-agent'] = system_agent
    end

    step('make aip descriptor') { make_aip_descriptor }
    step('validate aip descriptor') { validate_aip_descriptor }
    step('make tarball') { make_tarball }
    step('make aip') { save_aip }
    queue_report
  end

end
