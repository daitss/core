require 'dm-transactions'

require 'daitss/db/AIPInPremis'
require 'daitss/model/aip'
require 'daitss/model/aip/from_wip'
require 'daitss/proc/datafile/virus'
require 'daitss/proc/template/descriptor'
require 'daitss/proc/template/premis'

require 'daitss/proc/wip/preserve'
require 'daitss/proc/wip/tarball'
require 'daitss/proc/wip/to_aip'

module Daitss

  class Wip

    def ingest

      original_datafiles.each do |df|
        step("virus-check-#{df.id}") { df.virus_check! }
      end

      preserve

      step('write-ingest-event') do
        metadata['ingest-event'] = ingest_event package
      end

      step('write-ingest-agent') do
        metadata['ingest-agent'] = system_agent
      end

      step('make-aip-descriptor') do
        metadata['aip-descriptor'] = descriptor
      end

      step('make-tarball') { make_tarball }
      step('make-aip') { save_aip }
    end

  end

end
