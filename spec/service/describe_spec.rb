require 'spec_helper'
require "service/describe"

describe 'describing a datafile' do

  subject do
    wip = submit_sip 'haskell-nums-pdf'
    wip.datafiles.find { |df| df['sip-path'] =~ %r{\.pdf$} }
  end

  it "should know if something is described" do
    subject.should_not be_described
    subject.describe!
    subject.should be_described
  end

  describe "premis metadata" do
    before(:all) { subject.describe! }
    it { should have_key('describe-event') }
    it { should have_key('describe-agent') }
    it { should have_key('describe-object') }
  end

  it "should raise an error if something goes wrong"

end
