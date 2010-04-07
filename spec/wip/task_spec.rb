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

end
