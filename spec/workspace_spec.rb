require 'workspace'
require 'spec_helper'

describe Workspace do
  subject { Workspace.new $sandbox }

  it "should start all pending packages" do
    subject.start :all, TEST_STACK_CONFIG_FILE
    subject.tagged_with("INGEST").should_not be_empty
  end

  it "should start one pending package"
  it "should not start an ingesting package"

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
