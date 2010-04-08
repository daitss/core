require 'spec_helper'
require 'wip/process'
require 'uuid'

describe Wip do

  subject do
    id = UUID.generate :compact
    uri = "bogus:/#{id}"
    blank_wip id, uri
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
