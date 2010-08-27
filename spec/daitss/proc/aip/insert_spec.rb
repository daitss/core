require 'daitss/proc/wip/validate'
require 'spec_helper'
require 'daitss/proc/wip/preserve'
require 'daitss/model/aip/from_wip'

describe Aip do

  it "should create a new instance based on a WIP" do
    wip = submit 'mimi'
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

    Aip.new_from_wip wip
    Package.get(id).aip.should_not be_nil
  end

end
