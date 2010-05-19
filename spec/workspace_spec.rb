require 'spec_helper'
require 'workspace'
require 'stashbin'

describe Workspace do

  it "should know if it has a specific wip" do
    w = Workspace.new $sandbox
    wip = submit 'mimi', w
    w.should have_wip(wip.id)
    w.should_not have_wip('xxx')
  end

  it "should list packages" do
    w = Workspace.new $sandbox
    wips = %w(mimi haskell-nums-pdf).map { |name| submit name, w }
    w.should include(*wips)
  end

  it "should select packages by id" do
    w = Workspace.new $sandbox
    wip = submit 'mimi', w
    w[wip.id].should == wip
  end

  it "should stash & unstash a package" do
    bin = StashBin.new :name => 'test bin'
    ws = Workspace.new Daitss::CONFIG['workspace']
    wip = submit 'mimi', ws
    wip_id = wip.id
    ws.stash wip.id, bin
    ws[wip_id].should be_nil
    bin.unstash wip_id
    ws[wip_id].should_not be_nil
  end

end
