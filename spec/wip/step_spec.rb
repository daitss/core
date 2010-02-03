require 'spec_helper'
require 'wip'
require 'wip/step'

describe Wip do

  it "should should return a value of the block" do
    wip = submit_sip 'mimi'
    value = wip.step('add'){ 2 + 3 }
    value.should == 5
  end

  it "should make a step tag with the timestamp" do
    wip = submit_sip 'mimi'
    wip.step('add'){ 2 + 3 }
    wip.step_time('add').should_not be_nil
    wip.step_time('add').should < Time.now
  end

  it "should not perform an operation if the step has been performed" do
    wip = submit_sip 'mimi'
    wip.step('add'){ 2 + 3 }
    time = wip.step_time('add')
    wip.step('add'){ 2 + 3 }
    wip.step_time('add').should == time
  end

end
