require 'dm-transactions'

require 'daitss/proc/datafile/virus'
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
        step("virus check #{df.id}") { df.virus_check! }
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
    end

  end

end
