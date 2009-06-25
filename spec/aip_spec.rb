require 'spec_helper'
require 'aip'

describe Aip do
  
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
    pending
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
  
  it "handle arbitrary nested dirs (**/*)"
end
