require 'spec_helper'
require 'wip/task'
require 'uuid'

describe Wip do

  subject do
    id = UUID.generate :compact
    uri = "bogus:/#{id}"
    blank_wip id, uri
  end

  it "should have a task" do
    subject.task = :ingest
    subject.task.should == :ingest
  end

  it "should know when a package is done" do
    pending 'the semantics of this are in flux'
    subject.should_not be_done
    subject.task = :ingest
    subject.start { nil; subject.done! } # start a job of nothing
    sleep 0.5 # wait for it to finish up
    subject.should be_done
  end

  it 'should start based on task'
  it 'should stop a started task'
  it 'should start when stopped'

end
