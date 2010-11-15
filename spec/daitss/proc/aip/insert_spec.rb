require 'spec_helper'
require 'daitss/proc/wip/preserve'
require 'daitss/proc/wip/tarball'
require 'daitss/model/aip/from_wip'

describe Aip do

  it "should create a new instance based on a WIP" do
    wip = submit 'mimi'
    wip.preserve
    wip['aip-descriptor'] = wip.descriptor

    spec = {
      :id => "#{wip.uri}/event/ingest",
      :type => 'ingest',
      :outcome => 'success',
      :linking_objects => [ wip.uri ]
    }

    wip['ingest-event'] = event spec
    wip['aip-descriptor'] = wip.descriptor
    wip.make_tarball

    Aip.new_from_wip wip
    wip.package.aip.should_not be_nil
  end

end
