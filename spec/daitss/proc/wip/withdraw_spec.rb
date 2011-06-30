require 'daitss/proc/wip'
require 'daitss/proc/wip/ingest'
require 'daitss/proc/wip/withdraw'

require 'data_mapper'

describe Wip do

  
  describe "post withdrawal" do
    before :all do
      proto_wip = submit 'mimi'
      proto_wip.ingest
      @p = Package.get(proto_wip.id)
      @p.aip.should_not be_nil
      @copy_url = @p.aip.copy.url

      id = proto_wip.id
      path = proto_wip.path
      FileUtils.rm_r proto_wip.path

      @wip = Wip.make path, :withdraw
      @wip.withdraw
    end

    let(:doc) { XML::Document.string(@p.aip.xml) }

    it "should have a withdraw event" do
      doc.find("//P:event/P:eventType = 'withdraw'", NS_PREFIX).should be_true
    end

    it "should have a withdraw agent" do
      doc.find("//P:agent/P:agentName = '#{system_agent_spec[:name]}'", NS_PREFIX).should be_true
    end

    it "the descripto.should have no file level MD" do
      doc.find("//M:fileSec/M:fileGrp/M:file", NS_PREFIX).empty?.should be_true
      doc.find("//P:object[@xsi:type = 'file']", NS_PREFIX).empty?.should be_true
      doc.find("//P:object[@xsi:type = 'bitstream']", NS_PREFIX).empty?.should be_true
      doc.find("//P:object[@xsi:type = 'representation']", NS_PREFIX).empty?.should be_true

      doc.find("//P:event//P:eventType='transform'", NS_PREFIX).should be_false
      doc.find("//P:event//P:eventType='virus check'", NS_PREFIX).should be_false
      doc.find("//P:event//P:eventType='XML Resolution'", NS_PREFIX).should be_false
      doc.find("//P:event//P:eventType='describe'", NS_PREFIX).should be_false
    end

    it "should have no copies recorded in the db" do
      Package.get(@p.id).aip.copy.should be_nil
    end

    it "should have deleted the tarball" do
      tf = Tempfile.new "aip"

      c = Curl::Easy.new @copy_url
      c.follow_location = true
      c.http_get
      c.response_code.should == 410
    end
  end
end
