require 'old_ieid'
require 'helper'

describe OldIeid do

  before(:each) do
    DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/data/submission_svc_test.db")
    DataMapper.auto_migrate!

    a = add_account
    @o = add_operator a

  end

  def insert_test_event ieid, operations_agent
    e = operations_agent.operations_events.new(:timestamp => Time.now, 
                                               :event_name => "Test Event",
                                               :notes => "test message",
                                               :ieid => ieid) 
    e.save!
  end

  it "should return an IEID of E21000000_000000 when the database is empty" do
    OldIeid.get_next.should == "E21000000_000000"
  end 

  it "should return an IEID of E21000000_000000 when the database contains no DAITSS 1 style IEIDs" do
    insert_test_event "xxxx-xxxx-xxxx-xxxx-xxxx-xxxxx", @o
    insert_test_event "yyyy-yyyy-yyyy-yyyy-yyyy-yyyyy", @o
    insert_test_event "qqqq-qqqq-qqqq-qqqq-qqqq-qqqqq", @o
    insert_test_event "rrrr-rrrr-rrrr-rrrr-rrrr-rrrrr", @o

    OldIeid.get_next.should == "E21000000_000000"
  end

  it "should increment IEIDs as expected" do
    initial_ieid = "E21000000_ZZZZZY"

    insert_test_event initial_ieid, @o
    ieid1 = OldIeid.get_next

    insert_test_event ieid1, @o
    ieid2 = OldIeid.get_next

    insert_test_event ieid2, @o
    ieid3 = OldIeid.get_next

    insert_test_event ieid3, @o
    ieid4 = OldIeid.get_next

    ieid1.should == "E21000000_ZZZZZZ"
    ieid2.should == "E21000001_000000"
    ieid3.should == "E21000001_000001"
    ieid4.should == "E21000001_000002"
  end
end
