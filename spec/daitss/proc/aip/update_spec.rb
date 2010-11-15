require 'spec_helper'
require 'daitss/proc/wip/ingest'
require 'daitss/proc/wip/preserve'
require 'daitss/proc/wip/from_aip'
require 'daitss/model/aip'
require 'daitss/model/aip/from_wip'

describe Aip do

  describe "that does not exist" do
    subject { submit 'mimi' }

    it "should not update" do
      lambda { Aip.update_from_wip subject}.should raise_error("cannot access aip")
    end

  end

  describe "that exists" do

    subject do
      proto_wip = submit 'mimi'
      proto_wip.ingest
      path = proto_wip.path

      id = proto_wip.id

      FileUtils.rm_r path

      wip = Wip.make path, :disseminate
      wip.load_from_aip

      wip.preserve

      spec = {
        :id => "#{wip.uri}/event/FOO",
        :type => 'FOO',
        :outcome => 'success',
        :linking_objects => [ wip.uri ]
      }

      wip['old-digiprov-events'] = wip['old-digiprov-events'] + "\n" + event(spec)

      wip['aip-descriptor'] = wip.descriptor
      wip.make_tarball

      Aip.update_from_wip wip
      Package.get(id).aip
    end

    it "should update based on a WIP" do
      subject.should_not be_nil
    end

    it "should have the new metadata" do
      doc = XML::Document.string subject.xml
      doc.find("//P:event/P:eventType = 'FOO'", NS_PREFIX).should be_true
    end

  end


end
