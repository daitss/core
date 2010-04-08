require 'spec_helper'
require 'wip'
require 'uuid'

# Proto AIP: Work In Progress
describe Wip do

  subject do
    id = UUID.generate :compact
    uri = "bogus:/#{id}"
    blank_wip id, uri
  end

  it "should require a uri if one does not exist" do
    lambda {
      uuid = UUID.generate
      path = File.join $sandbox, uuid
      Wip.new path
    }.should raise_error(/wip .+ has no uri/)
  end

  it "should not require a uri if one already exists" do
    lambda {
      Wip.new subject.path, subject.uri
    }.should raise_error(/wip .+ has a uri/)
  end

  it "should let addition of new files" do
    df = subject.new_original_datafile 0
    df.open('w') { |io| io.write 'foo' }
    df.open { |io| io.read }.should == 'foo'
  end

  it "should not let the addition of existing datafiles" do
    subject.new_original_datafile 0
    lambda { subject.new_original_datafile 0 }.should raise_error /datafile 0 already exists/
  end

  it "should let addition of new metadata" do
    subject['submit-event'] = "submitted at #{Time.now}"

    wip_prime = Wip.new File.join($sandbox, subject.id)
    subject['submit-event'].should == wip_prime['submit-event']
  end

  it "should let new tags be set" do
    subject.tags['FOO'] = '100'
    subject.tags['FOO'].should == '100'
  end

  it "should have a uri" do
    subject.uri.should == "bogus:/#{subject.id}"
  end

  it "should equal a wip with the same path" do
    other = Wip.new subject.path
    subject.should == other
  end

  it "should not equal a wip with a different path" do
    uuid = UUID.generate :compact
    path = File.join $sandbox, uuid
    uri = "bogus:/#{uuid}"
    wip = Wip.new path, uri
    subject.should_not == wip
  end

end
