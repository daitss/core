require 'spec_helper'
require 'aip'
require 'archive'

describe Daitss::Aip do

  before(:each) do
    @httpd = test_web_server
    @handler = MockHandler.new
    @httpd.register "/", @handler
    @httpd.run
    @archive = Daitss::Archive.new "http://#{@httpd.host}:#{@httpd.port}/archive"
  end
  
  after(:each) do
    @httpd.stop
  end

  describe "ingest" do

    before(:each) do
      @aip = Daitss::Aip.new @archive, 'aip-0'
    end

    it "should terminate when there are any errors"
  end

  describe "validation" do
    
    before(:each) do
      @aip = Daitss::Aip.new @archive, 'aip-0'
      @handler.mock /^\/validity.*/, <<XML
<validity outcome="pass">
  <virus_check agent="vc-agent-uri" outcome="pass" />
  <virus_check agent="vc-agent-uri" outcome="pass" />
  <descriptor_valid agent="xml-validity-agent-uri" outcome="pass" />
  <checksum_valid agent="message-digest-agent-uri" outcome="pass" />
</validty>
XML
    end

    it "should be validated if validation has been performed" do
      pending "need aip resource functionality"
      @aip.validate
      @aip.should be_validated
    end

    it "should not be validated if validation has not been performed" do
      pending "need aip resource functionality"
      @aip.should_not be_validated
    end

    it "should have errors listed as events for an invalid aip" do
      #pending "not working right now"
      # TODO given some errors
      @aip.validate
      # @aip.should_not be_valid
      @aip.events.select { |e| e.agent =~ /validation/ }.should_not be_empty
    end

  end

end
