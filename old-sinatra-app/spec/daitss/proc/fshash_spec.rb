require 'daitss/proc/fshash'

describe FsHash do

  subject do
    FsHash.new $sandbox
  end

  it "should persist data between objects" do
    other = FsHash.new subject.path

    # has_key
    subject.should_not have_key('foo')

    # write
    subject['foo'] = 'bar'
    other['foo'].should == 'bar'
    subject.should have_key('foo')

    # overwrite
    subject['foo'] = 'baz'
    other['foo'].should == 'baz'

    # overwrite backwards
    other['foo'] = 'bax'
    subject['foo'].should == 'bax'

    # empty
    other['foo'] = nil
    subject['foo'].should == ""
    subject.should have_key('foo')

    # delete
    other.delete 'foo'
    subject.should_not have_key('foo')
    subject['foo'].should be_nil
  end

end
