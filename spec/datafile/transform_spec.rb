require 'spec_helper'
require 'datafile/transform'

describe DataFile do

  subject { submit_sip 'mimi' }

  it "should raise an error if the url is not a success" do
    lambda { 
      subject.datafiles.first.transform 'http://localhost/foo/bar'
    }.should raise_error(/Not Found/)
  end

  it "should get back an array of data and an extension if the transformation is good" do
    fs = subject.datafiles.first.transform 'http://localhost:7000/transformation/transform/pdf_norm'
    data, ext = fs.first
    data.should_not be_empty
    ext.should == '.tif'
  end

end
