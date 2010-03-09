require 'package_tracker'
require 'helper'
require 'spec_helper'
require 'time'

#TODO: add comments describing what each test is actually doing
describe PackageTracker do

  before :each do
    DataMapper.auto_migrate!
  end
  
  it "should add a new operations event" do
    a = add_account
    add_operator a

    PackageTracker.insert_op_event "operator", "xxxx-xxxx-xxxx-xxxx-xxxx-xxxxx", "WIP Stash", "this string should end up in the notes field"

    event = OperationsEvent.all.pop
    agent = event.operations_agent

    event.timestamp.to_time.should be_close(Time.now, 1.0)
    event.event_name == "WIP Stash"
    event.notes == "this string should end up in the notes field"
    event.ieid == "xxxx-xxxx-xxxx-xxxx-xxxx-xxxxx"

    agent.identifier.should == "operator"
  end

  it "should raise exception when adding an event associated with an agent that does not exist" do
    lambda { PackageTracker.insert_op_event "foovar", "xxxx-xxxx-xxxx-xxxx-xxxx-xxxxx", "WIP Stash", "this string should end up in the notes field" }.should raise_error
  end

  it "should raise exception when attempting to add an event with an empty or null name" do
    a = add_account
    add_operator a

    lambda { PackageTracker.insert_op_event "operator", "xxxx-xxxx-xxxx-xxxx-xxxx-xxxxx", "", "this string should end up in the notes field" }.should raise_error

    lambda { PackageTracker.insert_op_event "operator", "xxxx-xxxx-xxxx-xxxx-xxxx-xxxxx", nil, "this string should end up in the notes field" }.should raise_error
  end
end
