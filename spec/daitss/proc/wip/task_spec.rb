require 'spec_helper'
require 'daitss/proc/wip/task'
require 'uuid'
require 'daitss/proc/wip/ingest'
require 'daitss/archive'

describe Wip do

  before :all do
    ENV['PATH'] = [File.join(SPEC_ROOT, '..', 'bin'), ENV['PATH']].join ':'
  end

  subject do
    id = UUID.generate :compact
    uri = "bogus:/#{id}"
    blank_wip id, uri
  end

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
    ws = Archive.new.workspace
    wip = submit 'mimi'
    wip.task = :ingest
    wip.start
    sleep 0.5 while wip.running?
    wip.should_not be_snafu
    Package.get(wip.id).aip.should_not be_nil
    File.exist?(wip.path).should be_false
  end

  it 'should disseminate via task' do

    # ingest a package
    proto_wip = submit 'mimi'
    proto_wip.ingest!
    proto_wip.package.aip.should_not be_nil
    id, uri = proto_wip.id, proto_wip.uri
    FileUtils::rm_r proto_wip.path

    # move it to the workspace
    ws = Archive.new.workspace
    wip = blank_wip id, uri
    wip.tags['drop-path'] = "/tmp/#{id}.tar"
    FileUtils.mv wip.path, ws.path

    wip = ws[id]
    wip.task = :disseminate
    wip.start
    sleep 0.5 while wip.running?
    puts wip.snafu if wip.snafu?
    wip.should_not be_snafu
    wip.package.aip.should_not be_nil
    File.exist?(wip.path).should be_false
  end

end
