require 'archive'

describe Daitss::Archive do

  before(:each) do
    @httpd = test_web_server
    @handler = MockHandler.new
    @httpd.register "/", @handler
    @httpd.run
    @archive = Daitss::Archive.new "http://#{@httpd.host}:#{@httpd.port}/archive"
  end

  after(:each) do
    @httpd.stop
  end

  it "should create an AIP from a well formed sip" do
    sip = sip_by_name "ateam"
    lambda { aip = @archive.create_aip sip }.should_not raise_error
  end

  it "should return a list of AIPs that are not complete" do
    @handler.mock '/archive/_incompletes', <<XML
<incompletes>
  <aip url="ic-foo"/>
  <aip url="ic-bar"/>
  <aip url="ic-baz"/>
</incomplets>
XML
    @archive.incompletes.size.should == 3
  end


  it "should return a list of AIPs that are not complete" do
    @handler.mock '/archive/_snafus', <<XML
<snafus>
  <aip url="sf-foo"/>
  <aip url="sf-bar"/>
  <aip url="sf-baz"/>
</snafus>
XML
    @archive.snafus.size.should == 3
  end
  
  it "should return a list of AIPs that are not complete" do
    @handler.mock '/archive/_rejects', <<XML
<rejects>
  <aip url="rj-foo"/>
  <aip url="rj-bar"/>
  <aip url="rj-baz"/>
</rejects>
XML
    @archive.rejects.size.should == 3
  end
  
end
