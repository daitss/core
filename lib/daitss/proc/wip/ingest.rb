require 'daitss/proc/datafile/virus'
require 'daitss/db/ops/aip'
require 'daitss/db/ops/aip/from_wip'
require 'daitss/proc/descriptor'
require 'daitss/proc/template/premis'
require 'daitss/proc/wip'
require 'daitss/proc/wip/preserve'
require 'daitss/proc/wip/step'
require 'daitss/db/fast/AIPInPremis'
require 'dm-transactions'

class Wip

  def ingest!

    original_datafiles.each do |df|
      step("virus-check-#{df.id}") { df.virus_check! }
    end

    preserve!

    step('write-ingest-event') do
      spec = {
        :id => "#{uri}/event/ingest",
        :type => 'ingest',
        :outcome => 'success',
        :linking_objects => [ uri ],
        :linking_agents => [ "info:fcla/daitss/ingest" ]
      }
      metadata['ingest-event'] = event spec
    end

    step('write-ingest-agent') do
      spec = {
        :id => "info:fcla/daitss/ingest",
        :name => 'daitss ingest',
        :type => 'software'
      }
      metadata['ingest-agent'] = agent spec
    end

    step('make-aip-descriptor') do
      metadata['aip-descriptor'] = descriptor
    end

    step('make-aip') do

      Aip.transaction do
        aip = Aip.new_from_wip self
        doc = XML::Document.string(aip.xml)
        aipInPremis = AIPInPremis.new
        aipInPremis.process doc
      end

    end

  end

end
