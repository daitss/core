require 'spec_helper'
require 'wip'
require 'wip/disseminate'
require 'datamapper'

describe Wip do

  describe "that cannot disseminate" do

    it "should raise error if an aip does not exist for the wip" do
      wip = submit_sip 'mimi'
      lambda { wip.disseminate }.should raise_error(DataMapper::ObjectNotFoundError)
    end

    it "should raise error if there is anything wrong with dissemination" do
      proto_wip = submit_sip 'mimi'
      proto_wip.ingest!
      id, uri = proto_wip.id, proto_wip.uri
      FileUtils::rm_r proto_wip.path
      wip = blank_wip id, uri

      override_service 'description-url', 500 do
        lambda { wip.disseminate }.should raise_error(Net::HTTPFatalError)
      end

    end

  end

  describe "post disseminate" do

    subject do 
      proto_wip = submit_sip 'mimi'
      proto_wip.ingest!
      id, uri = proto_wip.id, proto_wip.uri
      FileUtils::rm_r proto_wip.path
      wip = blank_wip id, uri
      wip.disseminate
      wip
    end

    it "should have a disseminate event" do
      aip = Aip.get subject.id 
      aip.should_not be_nil
      doc = XML::Document.string aip.xml
      puts doc.to_s
      disseminate_event = doc.find_first "P:event[P:eventType = 'disseminate']", NS_PREFIX
      disseminate_event.should_not be_nil
    end

    it "should produce a dip in a disseminate area" do
      path = File.join CONFIG['disseminate-dir-path'], "#{subject.id}.tar"
      File.exist?(path).should be_true
    end

  end

end
