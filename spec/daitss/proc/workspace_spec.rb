require 'daitss/proc/workspace'
require 'daitss/proc/stashbin'

describe Workspace do

  it "should know if it has a specific wip" do
    w = Daitss.archive.workspace
    wip = submit 'mimi'
    w.should have_wip(wip.id)
    w.should_not have_wip('xxx')
  end

  it "should list packages" do
    w = Daitss.archive.workspace
    wips = %w(mimi haskell-nums-pdf).map { |name| submit name }
    w.should include(*wips)
  end

  it "should select packages by id" do
    w = Daitss.archive.workspace
    wip = submit 'mimi'
    w[wip.id].should == wip
  end

  it "should stash & unstash a package" do
    bin = StashBin.make! 'test bin'
    w = Daitss.archive.workspace
    wip = submit 'mimi'
    wip_id = wip.id
    w.stash wip.id, bin
    w[wip_id].should be_nil
    bin.unstash wip_id, ""
    w[wip_id].should_not be_nil
  end

end
