require 'workspace'
require 'spec_helper'

describe Workspace do

  subject { Workspace.new $sandbox }

  before(:each) do
    @aips = %w(haskell-nums-pdf ateam wave).map do |s| 
              File.basename submit_sip(s).path
            end
    @aip = @aips.first
  end

  after(:each) { FileUtils::rm_r Dir["#{$sandbox}/*"] }

  it "should start all pending packages" do
    subject.start :all, TEST_STACK_CONFIG_FILE
    subject.tagged_with("INGEST").should include(*@aips)
    subject.tagged_with("INGEST").should have_exactly(@aips.size).items
    subject.pending.should be_empty
  end

  it "should start one pending package" do
    subject.start @aip, TEST_STACK_CONFIG_FILE
    subject.tagged_with("INGEST").should include(@aip)
    subject.tagged_with("INGEST").should have_exactly(1).items
    subject.pending.should have_exactly(2).items
    subject.pending.should include(*@aips[1..-1])
  end

  it "should not start an ingesting package" do
    subject.start @aip, TEST_STACK_CONFIG_FILE
    lambda { subject.start @aip, TEST_STACK_CONFIG_FILE }.should raise_error("#{@aip} is ingesting")
    subject.pending.should include(*@aips[1..-1])
    subject.pending.should have_exactly(2).items
  end

  it "should stop all ingesting packages" do
    subject.start :all, TEST_STACK_CONFIG_FILE
    subject.stop :all
    subject.tagged_with("INGEST").should be_empty
    subject.tagged_with("STOP").should have_exactly(3).items
    subject.tagged_with("STOP").should include(*@aips) 
    subject.pending.should be_empty
  end

  it "should stop one ingesting package" do
    subject.start :all, TEST_STACK_CONFIG_FILE
    subject.stop @aip
    subject.tagged_with("INGEST").should_not include(@aip)
    subject.tagged_with("INGEST").should have_exactly(@aips.size - 1).items
    subject.tagged_with("STOP").should include(@aip)
    subject.tagged_with("STOP").should have_exactly(1).items
    subject.pending.should be_empty
  end

  it "should not stop an pending package" do
    subject.start :all, TEST_STACK_CONFIG_FILE
    subject.stop @aip
    lambda { subject.stop @aip }.should raise_error("#{@aip} is not ingesting")
    subject.tagged_with("STOP").should include(@aip)
    subject.tagged_with("STOP").should have_exactly(1).items
    subject.tagged_with("INGEST").should_not include(@aip)
    subject.tagged_with("INGEST").should have_exactly(@aips.size - 1).items
  end

  it "should stash a non ingesting package" do

    new_sandbox do |stash_dir|
      subject.stash @aip, stash_dir
      File.join(stash_dir, @aip).should exist_on_fs
      subject.pending.should_not include(@aip)
    end

  end

  it "should not stash an ingesting package" do
    subject.start @aip, TEST_STACK_CONFIG_FILE

    new_sandbox do |stash_dir|
      lambda { subject.stash @aip, stash_dir }.should raise_error("#{@aip} is ingesting")
    end

  end

  it "should unsnafu" do
    FileUtils::touch File.join($sandbox, @aip, "SNAFU")
    subject.tagged_with("SNAFU").should include(@aip)
    subject.unsnafu @aip
    subject.tagged_with("SNAFU").should be_empty
  end
  
  it "should not unsnafu a non-snafu package" do
    lambda { subject.unsnafu @aip }.should raise_error("#{@aip} is not SNAFU")
  end

  it "should list rejected packages" do
    FileUtils::touch File.join($sandbox, @aip, "REJECT")
    subject.tagged_with("REJECT").should include(@aip)
  end

  it "should list pending packages" do
    subject.pending.should include(*@aips)
  end

  it "should list all packages with state (ingest, STOP, pending)" do
    subject.start @aips[0], TEST_STACK_CONFIG_FILE
    subject.start @aips[1], TEST_STACK_CONFIG_FILE
    subject.stop @aips[1]

    status = subject.all_with_status
    status.should include("#{@aips[0]} ingesting")
    status.should include("#{@aips[1]} STOP")
    status.should include("#{@aips[2]} pending")
    status.should have_exactly(3).items
  end

  it "should list all packages with state (REJECT, SNAFU, pending)" do
    FileUtils::touch File.join($sandbox, @aips[0], "REJECT")
    FileUtils::touch File.join($sandbox, @aips[1], "SNAFU")

    status = subject.all_with_status
    status.should include("#{@aips[0]} REJECT")
    status.should include("#{@aips[1]} SNAFU")
    status.should include("#{@aips[2]} pending")
    status.should have_exactly(3).items
  end

end
