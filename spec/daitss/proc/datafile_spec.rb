require 'spec_helper'
require 'daitss/proc/datafile'

# Proto AIP: Work In Progress
describe DataFile do

  before :all do
    @wip = submit 'haskell-nums-pdf'
    @df = @wip.new_original_datafile 'test'
  end

  subject { @df }

  it "should let one add new metadata" do
    subject['sip-path'] = 'foo/bar/baz'
    subject['sip-path'].should == 'foo/bar/baz'
  end

  it "should let one read and write the data" do
    subject.open("w") { |io| io.write "foo" }
    subject.open { |io| io.read }.should == "foo"
  end

  it "should have a uri" do
    subject.uri.should == "#{subject.wip.package.uri}/file/#{subject.id}"
  end

  it "should equal datafiles with the same path" do
      df_1 = subject.wip.original_datafiles.first
      df_2 = subject.wip.original_datafiles.first

      df_1.should == df_2
  end

  it "should know its size" do
      subject.open('w') { |io| io.write '123' }
      subject.size.should == 3
  end

end
