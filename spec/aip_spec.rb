require 'spec_helper'
require 'aip'
require 'dm-core'
require "libxml"

include LibXML

describe Aip do

  after(:each) { nuke_sandbox! }
  
  it 'should create from a sip' do
    aip = aip_instance_from_sip 'ateam'
    aip.files.size.should == 2
    
    doc = XML::Parser.file(aip.poly_descriptor_file).parse
    doc.find('//mets:file', NS_MAP).size.should == 2
  end
  
  it "should initialize from a url" do
    aip = test_aip_by_name('good')
    lambda { Aip.new "file:#{aip}" }.should_not raise_error
  end
  
  it "should raise an error if it initialization fails" do
    lambda { Aip.new 'http://example.com/not/an/aip' }.should raise_error
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
    
  it "should know if it is currently rejected" do
    aip = aip_instance 'rejected'
    aip.should be_rejected
  end
  
  it "should know if it is currently snafu" do
    aip = aip_instance 'snafu'
    aip.should be_snafu
  end

  it "should write the descriptor to the database" do
    aip = aip_instance 'good'
    aip.ingest!
    aip.should_not be_snafu
    
    lambda { 
      AipResource.get! File.basename(aip.path)
    }.should_not raise_error(DataMapper::ObjectNotFoundError)
    
  end
  
  it "should store copies" do
    aip = aip_instance_from_sip 'ateam'
    aip.ingest!
    aip.should be_stored
  end
  
  it "should clean itself up" do
    aip = aip_instance_from_sip 'ateam'
    aip.cleanup!
    File.exist?(aip.path).should == false
  end
  
end
