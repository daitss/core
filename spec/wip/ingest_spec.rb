require 'wip'
require 'db/aip'
require 'wip/ingest'
require 'spec_helper'

describe Wip do

  describe "that wont ingest" do
    subject { submit_sip 'mimi' }

    it "should reject one that fails validation" do
      sip_descriptor = subject.datafiles.find { |df| df['sip-path'] == "mimi.xml" }
      subject.remove_datafile sip_descriptor
      lambda { subject.ingest! }.should raise_error(Reject)
    end

    it "should raise error if that has trouble ingesting" do

      override_service 'validation-url', 500 do
        lambda { subject.ingest! }.should raise_error(Net::HTTPFatalError)
      end

    end

  end

  describe "that is ingested" do

    before :all do
      @wip = submit_sip 'mimi'
      @wip.ingest!
    end

    it "should be validated" do
      @wip.tags.should have_key('validate')
    end

    it "should have an aip descriptor" do
      @wip.tags.should have_key('make-aip-descriptor')
    end

    it "should have made an aip" do
      Aip.get(@wip.id).should_not be_nil
    end

  end

end
