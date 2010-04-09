require 'wip'
require 'aip'
require 'wip/ingest'
require 'spec_helper'

describe Wip do

  describe "that wont ingest" do
    subject { submit 'mimi' }

    it "should raise error if that has trouble ingesting" do

      override_service 'description-url', 500 do
        lambda { subject.ingest! }.should raise_error(Net::HTTPFatalError)
      end

    end

  end

  describe "that is ingested" do

    before :all do
      @wip = submit 'mimi'
      @wip.ingest!
    end

    it "should have an aip descriptor" do
      @wip.should have_step('make-aip-descriptor')
    end

    it "should have an ingest event" do
      doc = XML::Document.string @wip['aip-descriptor']
      doc.find("//P:event/P:eventType = 'ingest'", NS_PREFIX).should be_true
    end

    it "should have an ingest agent" do
      doc = XML::Document.string @wip['aip-descriptor']
      doc.find("//P:agent/P:agentName = 'daitss ingest'", NS_PREFIX).should be_true
    end

    it "should have made an aip" do
      Aip.get(@wip.id).should_not be_nil
    end

  end

end
