require 'spec_helper'
require 'wip'
require 'aip'
require 'wip/ingest'

require 'db/int_entity'

describe Wip do

  describe "that wont ingest" do
    subject { submit 'mimi' }

    it "should raise error if that has trouble ingesting" do

      override_service 'describe', 500 do
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

    it "should have an IntEntity in the db" do
      ie = Intentity.get(@wip.uri)
      ie.should_not be_nil
      ie.should have(@wip.all_datafiles.size).datafiles
    end

    describe "the resulting aip" do

      before :all do
        @aip = Aip.get(@wip.id)
      end

      it "should have made an aip" do
        @aip.should_not be_nil
      end

      it "should put the xmlres tarball in the aip tarball" do
        url = @aip.copy_url
        req = Net::HTTP::Get.new url.path
        res = Net::HTTP.start(url.host, url.port) { |http| http.request req }

        Tempfile.open 'spec' do |t|
          t.write res.body
          t.flush
          tardata = %x{tar xOf #{t.path} #{@wip.id}/#{Wip::XML_RES_TARBALL}}
          $?.exitstatus.should == 0
          tardata.should_not be_nil
          tardata.should == @wip['xml-resolution-tarball']
        end

      end

    end

  end

end
