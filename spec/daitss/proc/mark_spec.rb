require 'daitss/proc/mark'

describe Mark do

  DELTA = 0.125
  subject do
    m = Mark.new
    m.start
    sleep DELTA
    m.finish
    m
  end

  it "should have a start time" do
    subject.start_time.should be_kind_of(Time)
  end

  it "should have an end time" do
    subject.start_time.should be_kind_of(Time)
  end

  it "should have a duration of about 1 second" do
    subject.duration.should be_close(DELTA, 0.01)
  end

  it "should serialze to a string and back" do
    m2 = Mark.parse subject.to_s
    m2.should == subject
  end

end
