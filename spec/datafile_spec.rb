require 'spec_helper'
require 'datafile'

# Proto AIP: Work In Progress
describe DataFile do

  subject do
    wip = Wip.new File.join($sandbox, UG.generate), 'bogus:/'
    wip.new_datafile
  end
  
  it "should let one add new metadata" do
    subject['sip-path'] = 'foo/bar/baz'
    subject['sip-path'].should == 'foo/bar/baz'
  end
  
  it "should let one read and write the data" do
    subject.open("w") { |io| io.write "foo" }
    subject.open { |io| io.read }.should == "foo"
  end

  it "should have a uri" do
    subject.uri.should == URI.join(subject.wip.uri, subject.id).to_s
  end
  
end
