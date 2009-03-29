require 'spec_helper'
require 'aip'
require 'archive'

describe Aip do

  before(:each) do
    @httpd = test_web_server
    @handler = AipHandler.new
    @httpd.register "/archive", @handler
    @httpd.run
    @archive = Archive.new "http://#{@httpd.host}:#{@httpd.port}/archive"
  end

  after(:each) do
    @httpd.stop
  end

  it "should construct given an archive and a " do
    given_aip = @archive.create_aip sip_by_name('ateam')
    lambda { Aip.new @archive, 'ateam' }.should_not raise_error
  end
  
  describe "ingest" do

    before(:each) do
      @aip = Aip.new @archive, 'aip-0'
    end
    
    it "should terminate when there are validation errors"
    it "should "
    
  end
  
  describe "validation" do
    it "should validate against a D2 validation service"
    it "should provide errors from validation service"
    it "should record event for validation outcome"
  end
  
  # its here until it finds a home
  describe "package level metadata" do
    it "should provide issue when available"
    it "should provide volume when available"
    it "should provide title when available"
  end

end
