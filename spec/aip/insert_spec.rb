require 'wip/validate'
require 'spec_helper'
require 'wip/preserve'
require 'db/aip/wip'

describe Aip do

  it "should create a new instance based on a WIP" do
    wip = submit_sip 'mimi'
    wip.validate!
    wip.preserve!
    wip['aip-descriptor'] = wip.descriptor

    spec = {
      :id => "#{wip.uri}/event/ingest", 
      :type => 'ingest', 
      :outcome => 'success', 
      :linking_objects => [ wip.uri ]
    }

    wip['ingest-event'] = event spec
    wip['aip-descriptor'] = wip.descriptor

    Aip::new_from_wip wip
    lambda { Aip.get! wip.id }.should_not raise_error(DataMapper::ObjectNotFoundError)
  end

end
