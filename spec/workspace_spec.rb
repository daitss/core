require 'workspace'
require 'spec_helper'

describe Workspace do

  subject { Workspace.new $sandbox }

  before(:each) do
    @aips = %w(haskell-nums-pdf ateam wave).map do |s| 
              File.basename submit_sip(s).path
            end
  end

  after(:each) { FileUtils::rm_r Dir["#{$sandbox}/*"] }

  it "should start all pending packages" do
    subject.start :all, TEST_STACK_CONFIG_FILE
    subject.tagged_with("INGEST").should include(*@aips)
    subject.tagged_with("INGEST").should have_exactly(@aips.size).items
  end

  it "should start one pending package" do
    aip = @aips.first
    subject.start aip, TEST_STACK_CONFIG_FILE
    subject.tagged_with("INGEST").should include(aip)
    subject.tagged_with("INGEST").should have_exactly(1).items
  end

  it "should not start an ingesting package" do
    aip = @aips.first
    subject.start aip, TEST_STACK_CONFIG_FILE
    lambda { subject.start aip, TEST_STACK_CONFIG_FILE }.should raise_error("#{aip} is ingesting")
  end

  it "should stop all ingesting packages"
  it "should stop one ingesting package"
  it "should not stop an pending package"

  it "should stash"
  it "should not stash an ingesting package"

  it "should unsnafu"
  it "should not unsnafu an unsnafu package"

  it "should list all packages with state"
  it "should list ingesting packages"
  it "should list stopped packages"
  it "should list rejected packages"
  it "should list pending packages"
  it "should list snafued packages"
end
