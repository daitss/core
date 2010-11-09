require 'spec_helper'
require 'daitss/proc/wip/step'


describe Wip do

  describe "taking soft steps" do

    it "should make a step tag with the timestamp" do
      wip = submit 'mimi'
      s = wip.step('add') { 2 + 3 }
      s[:time].should be_kind_of(Time)
      s[:duration].should be_kind_of(Float)
      s[:duration].should > 0
      s[:time].should < Time.now
    end

    it "should not perform an operation if the step has been performed" do
      wip = submit 'mimi'
      m1 = wip.step('add') { 2 + 3 }
      sleep 1.5
      m2 = wip.step('add') { 2 + 3 }
      m1.should == m2
    end

    it "should know if it has taken a step" do
      wip = submit 'mimi'
      wip.step('add') { 2 + 3 }
      wip.journal['add'].should_not be_nil
    end

  end

end
