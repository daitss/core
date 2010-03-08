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
      Aip.get! proto_wip.id
      id, uri = proto_wip.id, proto_wip.uri
      FileUtils::rm_r proto_wip.path
      wip = blank_wip id, uri
      wip.tags['drop-path'] = "/tmp/#{id}.tar"
      wip.disseminate
      wip
    end

    it "should have an disseminate event" do
      doc = XML::Document.string subject['aip-descriptor']
      doc.find("//P:event/P:eventType = 'disseminate'", NS_PREFIX).should be_true
    end

    it "should have an disseminate agent" do
      doc = XML::Document.string subject['aip-descriptor']
      doc.find("//P:agent/P:agentName = 'daitss disseminate'", NS_PREFIX).should be_true
    end

    it "should produce a dip in a disseminate area" do
      path = subject.tags['drop-path']
      File.exist?(path).should be_true
    end

  end

  describe "post multiple disseminations" do

    before :all do

      # ingest it
      proto_wip = submit_sip 'mimi'
      proto_wip.ingest!
      Aip.get! proto_wip.id
      @id, @uri = proto_wip.id, proto_wip.uri
      FileUtils::rm_r proto_wip.path

      # disseminate it twice
      2.times.each do |n|
        wip = blank_wip @id, @uri
        wip.tags['drop-path'] = "/tmp/#{@id}-#{n}.tar"
        wip.disseminate
        FileUtils::rm_r wip.path
      end

    end

    subject do
      aip = Aip.get! @id
      XML::Document.string aip.xml
    end

    it 'should have two dissemination events' do
      subject.find("count(//P:event[P:eventType = 'disseminate'])", NS_PREFIX).should == 2
    end

    it "should not collide identifiers" do
      events = subject.find("//P:event[P:eventType = 'disseminate']/P:eventIdentifier/P:eventIdentifierValue", NS_PREFIX)
      a = events[0].content
      b = events[1].content
      a.should_not == b

    end

    it "should have one dissemination agent" do
      subject.find("//P:agent/P:agentName = 'daitss disseminate'", NS_PREFIX).should be_true
    end

  end

end
