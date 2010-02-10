require 'wip'
require 'wip/step'
require 'wip/preserve'
require 'wip/load_aip'
require 'db/aip'
require 'db/aip/wip'
require 'descriptor'
require 'template/premis'

class Wip

  def disseminate

    step('load-aip') do
      load_from_aip
    end

    preserve!

    step('write-disseminate-event') do

      metadata['disseminate-event'] = event(:id => "#{uri}/event/disseminate", 
                                            :type => 'disseminate', 
                                            :outcome => 'success', 
                                            :linking_objects => [ uri ],
                                            :linking_agents => [ "info:fcla/daitss/disseminate" ])

    end

    step('write-disseminate-agent') do
      metadata['disseminate-agent'] = agent(:id => "info:fcla/daitss/disseminate", 
                                            :name => 'daitss disseminate',
                                            :type => 'software')
    end

    step('make-aip-descriptor') do
      metadata['aip-descriptor'] = descriptor
    end

    step('update-aip') { Aip::update_from_wip self }
  end

end
