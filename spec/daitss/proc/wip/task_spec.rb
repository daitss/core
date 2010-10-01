require 'spec_helper'
require 'daitss/proc/wip/task'
require 'uuid'
require 'daitss/proc/wip/ingest'
require 'daitss/archive'

describe Wip do

  before :all do
    ENV['PATH'] = [File.join(SPEC_ROOT, '..', 'bin'), ENV['PATH']].join ':'
  end

  subject { submit 'haskell-nums-pdf' }

  it "should have a task" do
    subject.task = :ingest
    subject.task.should == :ingest
  end

  it 'should start when stopped' do
    subject.task = :sleep
    subject.should_not be_running
    subject.start
    subject.should be_running
    subject.stop
    subject.should be_stopped
    subject.should_not be_running
  end

  it 'should ingest via task' do
    subject.start
    sleep 0.5 while subject.running?
    subject.should_not be_snafu
    Package.get(subject.id).aip.should_not be_nil
    File.exist?(subject.path).should be_false
  end

  it 'should disseminate via task' do
    subject.start
    sleep 0.5 while subject.running?
    subject.should_not be_snafu
    Package.get(subject.id).aip.should_not be_nil
    File.exist?(subject.path).should be_false

    ws = Daitss.archive.workspace
    path = File.join ws.path, subject.id
    wip = Wip.new path
    wip.tags['drop-path'] = "/tmp/#{wip.id}.tar"

    wip.task = :disseminate
    wip.start
    sleep 0.5 while wip.running?
    puts wip.snafu if wip.snafu?
    wip.should_not be_snafu
    wip.package.aip.should_not be_nil
    File.exist?(wip.path).should be_false
    File.exist?( "/tmp/#{wip.id}.tar").should be_true
  end

end
