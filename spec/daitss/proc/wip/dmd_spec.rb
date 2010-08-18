require 'spec_helper'
require 'daitss/proc/wip/dmd'

describe Wip, "with respect to dmd" do

  subject { submit 'mimi' }

  it "should know if dmd exists" do

    Wip::DMD_KEYS.each do |key|
      Wip::DMD_KEYS.each { |k| subject.delete k if subject.has_key? k }
      subject.should_not have_dmd
      subject[key] = "value for #{key}"
      subject.should have_dmd
    end

  end

  it "should make some xml for dmd if it exists" do
    subject['dmd-issue'] = CGI.escape "l'issue"
    subject['dmd-volume'] = 'le volume'
    subject['dmd-title'] = 'le titre'
    subject['dmd-entity-id'] = 'lentityid'
    doc = XML::Document.string subject.dmd
    doc.find("/mods:mods/mods:titleInfo/mods:title = '#{ subject['dmd-title'] }'", NS_PREFIX).should be_true
    doc.find("/mods:mods/mods:part/mods:detail[@type = 'volume']/mods:number = '#{ subject['dmd-volume'] }'", NS_PREFIX).should be_true
    doc.find("/mods:mods/mods:part/mods:detail[@type = 'issue']/mods:number = '#{ subject['dmd-issue'] }'", NS_PREFIX).should be_true
    doc.find("/mods:mods/mods:identifier[@type = 'entity id'] = '#{ subject['dmd-entity-id'] }'", NS_PREFIX).should be_true
  end

end
