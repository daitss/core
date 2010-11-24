require 'daitss/proc/wip'
require 'daitss/proc/wip/journal'
require 'daitss/proc/wip/preserve'
require 'daitss/proc/wip/from_d1'
require 'daitss/model/aip'
require 'daitss/model/aip/from_wip'
require 'daitss/proc/template/descriptor'
require 'daitss/proc/template/premis'
require 'daitss/proc/metadata'

module Daitss

  class Wip

    def d1refresh
      raise "no aip for #{id}" unless package.aip

      #TODO handle withdrawn packages

      step('load-aip') do
        load_from_d1_aip
      end

      preserve

      step('write-d1migrate-event') do
        metadata['d1migrate-event'] = d1migrate_event package, next_event_index('d1migrate')
      end

      step('write-d1migrate-agent') do
        metadata['d1migrate-agent'] = system_agent
      end

      step('make-aip-descriptor') do
        metadata['aip-descriptor'] = descriptor
      end

      step('make-tarball') do
        make_tarball
      end

      step('update-aip') do

        Aip.transaction do
          aip = Aip.update_from_wip self
          doc = XML::Document.string(aip.xml)
          aipInPremis = AIPInPremis.new
          aipInPremis.process aip.package, doc
        end

      end

    end

  end

end
