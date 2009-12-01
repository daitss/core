describe Workspace do
  it "should start all pending packages"
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
