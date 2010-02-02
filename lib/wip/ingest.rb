require 'wip'
require 'wip/step'
require 'wip/validate'
require 'wip/preserve'
require 'db/aip'
require 'db/aip/wip'
require 'descriptor'
require 'template/premis'

class Wip

  def ingest!
    
    begin
      step('validate') { validate! }
      preserve!

      step('make-aip-descriptor') do
        metadata['aip-descriptor'] = descriptor
      end

      step('write-ingest-event') do
        spec = {
          :id => "#{uri}/event/ingest", 
          :type => 'ingest', 
          :outcome => 'success', 
          :linking_objects => [ uri ]
        }
        metadata['ingest-event'] = event spec
      end

      step('make-aip') { Aip::new_from_wip self }
    rescue Reject => e
      tags['REJECT'] = e.message
    rescue => e
      tags['SNAFU'] = ( [e.message] + e.backtrace ).join "\n"
      puts tags['SNAFU']
    end

  end

end
