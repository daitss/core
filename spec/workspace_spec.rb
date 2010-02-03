require 'spec_helper'
require 'workspace'

describe Workspace do

  it "should know if it has a specific wip" do
    w = Workspace.new $sandbox
    wip = submit w, 'mimi'
    w.should have_wip(wip.id)
    w.should_not have_wip('xxx')
  end

  it "should list packages" do
    w = Workspace.new $sandbox
    wips = %w(mimi haskell-nums-pdf).map { |name| submit w, name }
    w.should include(*wips)
  end

  it "should select packages by id" do
    w = Workspace.new $sandbox
    wip = submit w, 'mimi'
    w[wip.id].should == wip
  end

  it "stashing a bogus wip should raise an error" do

    new_sandbox do |stash_bin|
      w = Workspace.new $sandbox
      wip = submit w, 'mimi'
      lambda { s.stash 'xxx', stash_bin }.should raise_error
    end

  end

  it "stashing to a bogus dir should raise an error" do
    w = Workspace.new $sandbox
    wip = submit w, 'mimi'
    lambda { w.stash wip.id, 'xxx/yyy/zzz' }.should raise_error
  end

  it "unstashing a non wip should raise an error" do
    w = Workspace.new $sandbox
    lambda { w.unstash 'xxx/yyy/zzz' }.should raise_error
  end

  it "should stash & unstash a package" do
    new_sandbox do |stash_bin|
      w = Workspace.new $sandbox

      wip = submit w, 'mimi'
      wip_id = wip.id

      w.stash wip.id, stash_bin
      w[wip_id].should be_nil
      w.unstash File.join(stash_bin, wip_id)
      w[wip_id].should_not be_nil
    end

  end


end
