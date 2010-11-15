require 'spec_helper'
require 'daitss/proc/wip'
require 'daitss/model/aip'
require 'daitss/proc/wip/ingest'

require 'daitss/db/int_entity'

describe Wip do

  describe "that is ingested" do

    before :all do
      @wip = submit 'mimi'
      @wip.ingest
    end

    it "should have an aip descriptor" do
      @wip.journal['make-aip-descriptor'].should_not be_nil
    end

    describe "aip descriptor" do

      subject do
        XML::Document.string @wip['aip-descriptor']
      end

      it "should have an ingest event" do
        subject.find("//P:event/P:eventType = 'ingest'", NS_PREFIX).should be_true
      end

      it "should have an ingest agent" do
        subject.find("//P:agent/P:agentName = '#{system_agent_spec[:name]}'", NS_PREFIX).should be_true
      end

      it "should have a sip descriptor denoted" do
        subject.find("//M:file/@USE='sip descriptor'", NS_PREFIX).should be_true
      end

    end


    it "should have an IntEntity in the db" do
      ie = Intentity.get(@wip.uri)
      ie.should_not be_nil
      ie.should have(@wip.all_datafiles.size).datafiles
    end

    describe "the resulting aip" do

      before :all do
        @aip = @wip.package.aip
      end

      it "should have made an aip" do
        @aip.should_not be_nil
      end

      it "should put the xmlres tarball in the aip tarball" do
        url = @aip.copy.url
        req = Net::HTTP::Get.new url.path
        res = Net::HTTP.start(url.host, url.port) { |http| http.request req }

        Tempfile.open 'spec' do |t|
          t.write res.body
          t.flush
          tarfile = File.join @wip.id, "#{Wip::XML_RES_TARBALL_BASENAME}-0.tar"
          tardata = %x{tar xOf #{t.path} #{tarfile}}
          $?.exitstatus.should == 0
          tardata.should_not be_nil
          tardata.should == @wip['xml-resolution-tarball']
        end

      end

    end

  end

end
