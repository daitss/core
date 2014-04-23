require 'dm-transactions'

require 'daitss/service/virus'
require 'daitss/proc/template/descriptor'
require 'daitss/proc/template/premis'
require 'daitss/proc/wip/preserve'
require 'daitss/proc/wip/tarball'
require 'daitss/proc/wip/to_aip'
require 'daitss/proc/xmlvalidation'

module Daitss

  class Wip

    def ingest

      original_datafiles.each do |df|

        step("virus check #{df.id}") do
          begin
            vc = Virus.new df.data_file, df.uri
            vc.post
            df.metadata['virus-check-event'] = vc.event
            df.metadata['virus-check-agent'] = vc.agent
            raise "virus detected\n#{vc.note}" if vc.failed?
          rescue Interrupt
            exit 1
          end
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
      queue_report :ingest
    end

  end

end
