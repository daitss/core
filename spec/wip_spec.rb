require 'spec_helper'
require 'wip'
require 'uuid'
require 'uri'
gen = UUID.new

# Proto AIP: Work In Progress
describe Wip do

  subject do
    uuid = gen.generate
    path = File.join $sandbox, uuid
    uri = URI.join('bogus:/', uuid) .to_s
    Wip.new path, uri
  end

  it "should require a uri if one does not exist" do
    lambda { 
      uuid = gen.generate
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
    df = subject.new_datafile 
    df['sip-path'] = 'foo/bar.png'
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
    subject.uri.should == URI.join("bogus:/", subject.id).to_s 
  end

end
