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
  end

  it "should start one pending package" do
    subject.start @aip, TEST_STACK_CONFIG_FILE
    subject.tagged_with("INGEST").should include(@aip)
    subject.tagged_with("INGEST").should have_exactly(1).items
  end

  it "should not start an ingesting package" do
    subject.start @aip, TEST_STACK_CONFIG_FILE
    lambda { subject.start @aip, TEST_STACK_CONFIG_FILE }.should raise_error("#{@aip} is ingesting")
  end

  it "should stop all ingesting packages" do
    subject.start :all, TEST_STACK_CONFIG_FILE
    subject.stop :all
    subject.tagged_with("INGEST").should be_empty
  end

  it "should stop one ingesting package" do
    subject.start :all, TEST_STACK_CONFIG_FILE
    subject.stop @aip
    subject.tagged_with("INGEST").should_not include(@aip)
    subject.tagged_with("INGEST").should_not have_exactly(@aips.size - 1).items
  end

  it "should not stop an pending package" do
    subject.start :all, TEST_STACK_CONFIG_FILE
    subject.stop @aip
    lambda { subject.stop @aip }.should raise_error("#{@aip} is not ingesting")
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


  it "should list all packages with state"
  it "should list ingesting packages"
  it "should list stopped packages"
  it "should list rejected packages"
  it "should list pending packages"
  it "should list snafued packages"
end
