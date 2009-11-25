require 'spec_helper'
require 'workspace'

describe State do

  subject { State.new $sandbox }

  it "should read empty when nothing is being processed" do
    subject.should be_empty
  end

  it "should not be empty when something is appended" do
    subject.append "aip-1", "job-12"
    subject.should_not be_empty
  end

  it "should record what is written" do
    fixture = [%w(foo j-5), %w(bar j-2), %w(baz j-99)]
    subject.write fixture
    subject.should_not be_empty

    fixture.each do |f|
      subject.should include(f)
    end

  end

  it "should not contain stale jobs" do
    pid = fork {}
    job = 'xxx', pid.to_s
    subject.append *job
    Process.wait pid
    subject.should_not include(job)
  end

end

