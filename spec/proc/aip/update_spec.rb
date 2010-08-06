require 'spec_helper'
require 'wip/ingest'
require 'wip/preserve'
require 'wip/from_aip'
require 'aip'
require 'aip/from_wip'

describe Aip do

  describe "that does not exist" do
    subject { submit 'mimi' }

    it "should not update" do
      lambda { Aip::update_from_wip subject}.should raise_error(DataMapper::ObjectNotFoundError)
    end

  end

  describe "that exists" do

    subject do
      proto_wip = submit 'mimi'
      proto_wip.ingest!
      path = proto_wip.path
      FileUtils.rm_r path
      wip = Wip.from_aip path
      wip.preserve!

      spec = {
        :id => "#{wip.uri}/event/FOO",
        :type => 'FOO',
        :outcome => 'success',
        :linking_objects => [ wip.uri ]
      }

      wip['old-digiprov-events'] = wip['old-digiprov-events'] + "\n" + event(spec)

      wip['aip-descriptor'] = wip.descriptor
      Aip.update_from_wip wip
      Aip.get! wip.id
    end

    it "should update based on a WIP" do
      lambda { Aip.get! subject.id }.should_not raise_error(DataMapper::ObjectNotFoundError)
    end

    it "should have the new metadata" do
      doc = XML::Document.string subject.xml
      doc.find("//P:event/P:eventType = 'FOO'", NS_PREFIX).should be_true
    end

  end


end
