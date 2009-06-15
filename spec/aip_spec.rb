require 'tempfile'
require 'fileutils'

require 'spec_helper'
require 'aip'

describe Aip do

  before(:each) do
    $sandbox = new_sandbox
    FileUtils::mkdir $sandbox
  end
  
  after(:each) do
    FileUtils::rm_rf $sandbox
  end
  
  it 'should create from a sip' do
    aip = aip_instance_from_sip 'ateam'
    aip.files.size.should == 2
    
    doc = XML::Parser.file(aip.descriptor_file).parse
    doc.find('//mets:file', NS_MAP).size.should == 2
  end
  
  it "should initialize from a url" do
    aip = test_aip_by_name('good')
    lambda { Aip.new "file:#{aip}" }.should_not raise_error
  end
  
  it "should raise an error if it initialization fails" do
    lambda { Aip.new 'http://example.com/not/an/aip' }.should raise_error
  end

  it "should validate" do
    aip = aip_instance 'good'
    aip.should_not be_validated
    lambda { aip.validate }.should_not raise_error(Reject)
    aip.should be_validated
  end

  it "should raise a rejection error if validation fails" do
    aip = aip_instance 'invalid-descriptor'
    aip.should_not be_validated
    lambda { aip.validate }.should raise_error(Reject)
    aip.should be_validated
  end

  it "should record incoming provenance" do
    pending "external provenance extractor not returning an event, might be a bug"
    aip = aip_instance 'preexisting-digiprov'
    aip.should_not be_provenance_retrieved
    lambda { aip.retrieve_provenance }.should_not raise_error
    aip.should be_provenance_retrieved
  end
    
  it "should provide a set of files" do
    aip = aip_instance 'good'
    aip.files.size.should == 2
  end
    
  it "should allow the addition of files" do
    aip = aip_instance 'good'
    aip.files.size.should == 2
    io = StringIO.new 'some new stuff'
    aip.add_file io
    aip.files.size.should == 3
  end
  
  it "should store copies"
  
  it "should know if it is currently rejected" do
    pending "reject file is written by ingest script"
    aip = aip_instance 'invalid-descriptor'
    lambda { aip.ingest! }.should raise_error(Reject)
    aip.should be_rejected
  end
  
  it "should know if it is currently ingested" do
    aip = aip_instance 'good'
    aip.ingest! 
    aip.should_not be_rejected
    aip.should_not be_snafu
  end
  
  it "should know if it is currently snafu" do
    pending "we need a test stack to make a snafu"
    aip = aip_instance 'good'
    aip.ingest!
    aip.should be_snafu
  end
  
  it "should put data files in rep-0" do
    aip = aip_instance_from_sip 'ateam'
    
    aip.files.each do |file|
      dir = File.split(file.path).first
      dir.should == 'rep-0'
    end
    
  end
  
  it 'should put migrated files in rep-1' do
    aip = aip_instance_from_sip 'glass'
    puts aip.files.inspect
        puts 'ingested!'
    aip.ingest!

    puts aip.files.inspect
    file = aip.files.find { |f| puts f.path; File.basename(f.path) == 'transformed.wav' }
    dir = File.split(file.path).first
    dir.should == 'rep-1'
  end
  
  it "handle arbitrary nested dirs (**/*)"
end
