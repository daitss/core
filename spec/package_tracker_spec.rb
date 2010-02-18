require 'package_tracker'
require 'helper'
require 'pp'

describe PackageTracker do
  
  before(:each) do
    DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/data/daitss-core.db")
    DataMapper.auto_migrate!
  end

  it "should add a new operations event" do
    a = add_account
    add_operator a

    PackageTracker.insert_op_event "operator", "xxxx-xxxx-xxxx-xxxx-xxxx-xxxxx", "WIP Stash", "this string should end up in the notes field"

    event = OperationsEvent.all(:operations_agent => {:identifier => "operator"})   #event = OperationsEvent.all

    pp event
  end
end
