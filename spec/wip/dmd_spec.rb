require 'spec_helper'
require 'wip/dmd'

describe Wip, "with respect to dmd" do

  subject { submit_sip 'mimi' }

  it "should know if dmd exists" do
    subject.should_not have_dmd
    subject['dmd-issue'] = 'volume 4'
    subject.should have_dmd
  end

  it "should make some xml for dmd if it exists" do
    subject['dmd-issue'] = CGI.escape "l'issue"
    subject['dmd-volume'] = 'le volume'
    subject['dmd-title'] = 'le titre'
    doc = XML::Document.string subject.dmd
    doc.find("/mods:mods/mods:titleInfo/mods:title = '#{ subject['dmd-title'] }'", NS_PREFIX).should be_true
    doc.find("/mods:mods/mods:part/mods:detail[@type = 'volume']/mods:number = '#{ subject['dmd-volume'] }'", NS_PREFIX).should be_true
    doc.find("/mods:mods/mods:part/mods:detail[@type = 'issue']/mods:number = '#{ subject['dmd-issue'] }'", NS_PREFIX).should be_true
  end

end
