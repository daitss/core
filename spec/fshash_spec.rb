require 'tempfile'
require 'fshash'

describe FsHash do

  subject do
    t = Tempfile.new FsHash.name
    path = t.path
    t.close!
    FsHash.new path
  end

  after :all do
    subject.path
  end

  it "should persist data between objects" do
    other = FsHash.new subject.path

    subject['foo'] = 'bar'
    other['foo'].should == 'bar'
    
    subject['foo'] = 'baz'
    other['foo'].should == 'baz'

    other['foo'].should == 'bax'
    subject['foo'].should = 'bax'
  end

end
