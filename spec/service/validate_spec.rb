require 'spec_helper'
require 'service/validate'

describe 'validating a wip' do

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
    subject.validate!
    subject.should have_key('validate-event')
  end

  it "should have a validation agent" do
    subject.validate!
    subject.should have_key('validate-agent')
  end

  it "should reject if something fails validation" do
    descriptor = subject.datafiles.find { |df| df['sip-path'] == "#{subject['sip-name']}.xml" }
    doc = descriptor.open { |io| XML::Document.io io }
    doc.find("//@ID").each { |node| node.remove! }
    descriptor.open('w') { |io| io.write doc.to_s }
    lambda { subject.validate! }.should raise_error Reject
  end

end
