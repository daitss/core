require 'spec_helper'
require 'workspace'
require 'wip'

describe Workspace do

  subject { Workspace.new $sandbox }

  before(:each) do
    @wips = %w(haskell-nums-pdf ateam wave).map do |s| 
              File.basename submit_sip(s).path
            end
    @wip = @wips.first
  end

  after(:each) { FileUtils::rm_r Dir["#{$sandbox}/*"] }

  it "should start all pending packages" do
    subject.start :all, TEST_STACK_CONFIG_FILE
    subject.tagged_with("INGEST").should include(*@wips)
    subject.tagged_with("INGEST").should have_exactly(@wips.size).items
    subject.pending.should be_empty
  end

  it "should start one pending package" do
    subject.start @wip, TEST_STACK_CONFIG_FILE
    subject.tagged_with("INGEST").should include(@wip)
    subject.tagged_with("INGEST").should have_exactly(1).items
    subject.pending.should have_exactly(2).items
    subject.pending.should include(*@wips[1..-1])
  end

  it "should not start an ingesting package" do
    subject.start @wip, TEST_STACK_CONFIG_FILE
    lambda { subject.start @wip, TEST_STACK_CONFIG_FILE }.should raise_error("#{@wip} is ingesting")
    subject.pending.should include(*@wips[1..-1])
    subject.pending.should have_exactly(2).items
  end

  it "should stop all ingesting packages" do
    subject.start :all, TEST_STACK_CONFIG_FILE
    subject.stop :all
    subject.tagged_with("INGEST").should be_empty
    subject.tagged_with("STOP").should have_exactly(3).items
    subject.tagged_with("STOP").should include(*@wips) 
    subject.pending.should be_empty
  end

  it "should stop one ingesting package" do
    subject.start :all, TEST_STACK_CONFIG_FILE
    subject.stop @wip
    subject.tagged_with("INGEST").should_not include(@wip)
    subject.tagged_with("INGEST").should have_exactly(@wips.size - 1).items
    subject.tagged_with("STOP").should include(@wip)
    subject.tagged_with("STOP").should have_exactly(1).items
    subject.pending.should be_empty
  end

  it "should not stop an pending package" do
    subject.start :all, TEST_STACK_CONFIG_FILE
    subject.stop @wip
    lambda { subject.stop @wip }.should raise_error("#{@wip} is not ingesting")
    subject.tagged_with("STOP").should include(@wip)
    subject.tagged_with("STOP").should have_exactly(1).items
    subject.tagged_with("INGEST").should_not include(@wip)
    subject.tagged_with("INGEST").should have_exactly(@wips.size - 1).items
  end

  it "should stash a non ingesting package" do

    new_sandbox do |stash_dir|
      subject.stash @wip, stash_dir
      File.join(stash_dir, @wip).should exist_on_fs
      subject.pending.should_not include(@wip)
    end

  end

  it "should not stash an ingesting package" do
    subject.start @wip, TEST_STACK_CONFIG_FILE

    new_sandbox do |stash_dir|
      lambda { subject.stash @wip, stash_dir }.should raise_error("#{@wip} is ingesting")
    end

  end

  it "should unsnafu" do
    FileUtils::touch File.join($sandbox, @wip, "SNAFU")
    subject.tagged_with("SNAFU").should include(@wip)
    subject.unsnafu @wip
    subject.tagged_with("SNAFU").should be_empty
  end
  
  it "should not unsnafu a non-snafu package" do
    lambda { subject.unsnafu @wip }.should raise_error("#{@wip} is not SNAFU")
  end

  it "should list rejected packages" do
    FileUtils::touch File.join($sandbox, @wip, "REJECT")
    subject.tagged_with("REJECT").should include(@wip)
  end

  it "should list pending packages" do
    subject.pending.should include(*@wips)
  end

  it "should list all packages with state (ingest, STOP, pending)" do
    subject.start @wips[0], TEST_STACK_CONFIG_FILE
    subject.start @wips[1], TEST_STACK_CONFIG_FILE
    subject.stop @wips[1]

    status = subject.all_with_status
    status.should include("#{@wips[0]} ingesting")
    status.should include("#{@wips[1]} STOP")
    status.should include("#{@wips[2]} pending")
    status.should have_exactly(3).items
  end

  it "should list all packages with state (REJECT, SNAFU, pending)" do
    FileUtils::touch File.join($sandbox, @wips[0], "REJECT")
    FileUtils::touch File.join($sandbox, @wips[1], "SNAFU")

    status = subject.all_with_status
    status.should include("#{@wips[0]} REJECT")
    status.should include("#{@wips[1]} SNAFU")
    status.should include("#{@wips[2]} pending")
    status.should have_exactly(3).items
  end

end
