require 'spec_helper'
require 'wip'
require 'wip/task'
require 'wip/process'
require 'uuid'
require 'uri'

# Proto AIP: Work In Progress
describe Wip do

  subject do
    uuid = UUID.generate
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

  it "should let the addition of new files by a given id" do
    the_id = 5.to_s
    df = subject.new_datafile the_id
    subject.datafiles.first.id.should == the_id
  end

  it "should let removal of files" do
    df = subject.new_datafile
    subject.remove_datafile df
    subject.datafiles.should_not include(df)
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

  it "should equal a wip with the same id, uri and path" do
    other = Wip.new subject.path
    subject.should == other
  end

  it "should have a task" do
    subject.task = :ingest
    subject.task.should == :ingest
  end

  it "should monitor the processing state (idle, running, done)" do
    subject.should_not be_running
    subject.start { sleep }
    subject.should be_running
    subject.stop
    subject.should_not be_running
    subject.should_not be_done
  end

  it "should know when a package is done" do
    subject.should_not be_done
    subject.start { nil } # start a job of nothing
    sleep 1 # wait for it to finish up
    subject.should be_done
  end

end
