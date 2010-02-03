require 'spec_helper'
require 'xmlns'
require 'datafile/describe'
require 'datafile/actionplan'

describe 'action planning a datafile' do

  subject do
    wip = submit_sip 'mimi'
    df = wip.datafiles.find { |df| df['sip-path'] == 'mimi.pdf' }
    df.describe!
    df
  end

  it "should return nil if there is no migration" do
    subject.migration.should be_nil
  end

  it "should redirect if there is a transformation" do
    subject.normalization.should == 'http://localhost:7000/transformation/transform/pdf_norm'
  end

  it "should raise an error is the the configuration is wrong" do
    real_actionplan_url = CONFIG['actionplan-url']
    CONFIG['actionplan-url'] = 'http://localhost:7000/statusecho/500'
    lambda { subject.normalization }.should raise_error
    CONFIG['actionplan-url'] = real_actionplan_url

  end

end
