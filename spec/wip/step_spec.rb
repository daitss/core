require 'spec_helper'
require 'wip/step'


describe Wip do

  describe "taking soft steps" do

    it "should make a step tag with the timestamp" do
      wip = submit_sip 'mimi'
      mark = wip.step('add'){ 2 + 3 }
      mark.duration.should > 0
      mark.start_time.should < mark.finish_time
      mark.finish_time.should < Time.now
    end

    it "should not perform an operation if the step has been performed" do
      wip = submit_sip 'mimi'
      m1 = wip.step('add'){ 2 + 3 }
      sleep 1.5
      m2 = wip.step('add'){ 2 + 3 }
      m1.should == m2
    end

    it "should know if it has taken a step" do
      wip = submit_sip 'mimi'
      wip.step('add'){ 2 + 3 }
      wip.should have_step('add')
    end

  end

  describe "taking hard steps" do

    it "should perform an operation even if the step has been performed" do
      wip = submit_sip 'mimi'
      m1 = wip.step('add'){ 2 + 3 }
      sleep 1.5
      m2 = wip.step!('add'){ 2 + 3 }
      m1.start_time.should < m2.start_time
      m1.finish_time.should < m2.finish_time
    end

  end

end
