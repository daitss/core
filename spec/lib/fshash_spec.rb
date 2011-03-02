require 'tmpdir'
require 'proc/fshash'

describe FsHash do

  before :all do
    @sandbox = Dir.mktmpdir
  end

  after :all do
    FileUtils.rm_r @sandbox
  end

  let :fshash do
    FsHash.new @sandbox
  end

  let :other do
    FsHash.new fshash.path
  end


  it "should persist data between objects" do

    # has_key
    fshash.should_not have_key('foo')

    # write
    fshash['foo'] = 'bar'
    other['foo'].should == 'bar'
    fshash.should have_key('foo')

    # overwrite
    fshash['foo'] = 'baz'
    other['foo'].should == 'baz'

    # overwrite backwards
    other['foo'] = 'bax'
    fshash['foo'].should == 'bax'

    # empty
    other['foo'] = nil
    fshash['foo'].should == ""
    fshash.should have_key('foo')

    # delete
    other.delete 'foo'
    fshash.should_not have_key('foo')
    fshash['foo'].should be_nil
  end

end
