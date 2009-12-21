require 'spec_helper'
require 'service/validate'

describe Service::Validate do

  subject do
    wip = submit_sip 'haskell-nums-pdf'
    wip.extend Service::Validate
    wip
  end

  it "should know if something is validated" do
    subject.should_not be_validated
    subject.validate!
    subject.should be_validated
  end

  it "should have a validation event" do
    subject.should have_key('validate-event')
  end

  it "should have a validation agent" do
    subject.should have_key('validate-agent')
  end

  it "should reject if something fails validation" do
    subject.files[0].open(:a) { |io| io.puts "oops" }
    lambda { subject.validate! }.should raise_error Reject
  end

end
