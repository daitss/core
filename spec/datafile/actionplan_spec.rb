require 'spec_helper'
require 'xmlns'
require 'datafile/describe'
require 'datafile/actionplan'

describe 'action planning a datafile' do

  subject do
    wip = submit 'wave'
    df = wip.original_datafiles.find { |df| df['sip-path'] == 'obj1.wav' }
    df.describe!
    df
  end

  it "should return nil if there is no migration" do
    subject.migration.should be_nil
  end

  it "should redirect if there is a transformation" do
    subject.normalization.should == 'http://localhost:7000/transformation/transform/wave_norm'
  end

  it "should raise an error is the the configuration is wrong" do
    real_actionplan_url = Daitss::CONFIG['actionplan-url']
    Daitss::CONFIG['actionplan-url'] = 'http://localhost:7000/statusecho/500'
    lambda { subject.normalization }.should raise_error
    Daitss::CONFIG['actionplan-url'] = real_actionplan_url
  end

end
