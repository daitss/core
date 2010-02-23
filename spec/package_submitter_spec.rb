require 'package_submitter'
require 'fileutils'
require 'libxml'
require 'package_tracker'

describe PackageSubmitter do

  DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/data/submission_svc_test.db")

  ZIP_SIP = "spec/test-sips/ateam.zip"
  TAR_SIP = "spec/test-sips/ateam.tar"
  ZIP_SIP_NODIR = "spec/test-sips/ateam-nodir.zip"
  TAR_SIP_NODIR = "spec/test-sips/ateam-nodir.tar"
  ZIP_NO_DESCRIPTOR = "spec/test-sips/ateam-nodesc.zip"
  ZIP_DMD_METADATA = "spec/test-sips/ateam-dmd.zip"
  ZIP_BROKEN_DESCRIPTOR = "spec/test-sips/ateam-broken-descriptor.zip"

  URI_PREFIX = "test:/"

  before(:each) do
    FileUtils.mkdir_p "/tmp/d2ws"
    ENV["DAITSS_WORKSPACE"] = "/tmp/d2ws"

    LibXML::XML.default_keep_blanks = false
  end

  after(:each) do
    FileUtils.rm_rf "/tmp/d2ws"
  end

  it "should raise error on create AIP from ZIP file if DAITSS_WORKSPACE is not set to a valid dir" do
    ENV["DAITSS_WORKSPACE"] = ""

    lambda { PackageSubmitter.submit_sip :zip, ZIP_SIP, "ateam", "0.0.0.0", "cccccccccccccccccccccccccccccccc" }.should raise_error
  end

  it "should raise error on create AIP from TAR file if DAITSS_WORKSPACE is not set to a valid dir" do
    ENV["DAITSS_WORKSPACE"] = ""

    lambda { PackageSubmitter.submit_sip :tar, TAR_SIP, "ateam", "0.0.0.0", "cccccccccccccccccccccccccccccccc" }.should raise_error
  end

  it "should generate a unique IEID for each AIP created" do
    ieid_1 = PackageSubmitter.submit_sip :zip, ZIP_SIP, "ateam", "operator", "0.0.0.0", "cccccccccccccccccccccccccccccccc" 
    ieid_2 = PackageSubmitter.submit_sip :tar, TAR_SIP, "ateam", "operator", "0.0.0.0", "cccccccccccccccccccccccccccccccc"

    ieid_1.should_not == ieid_2
  end

  it "should submit a package creating a wip with submission event from a tar-extracted SIP and a PT event" do
    now = Time.now
    ieid = PackageSubmitter.submit_sip :tar, TAR_SIP_NODIR, "ateam", "operator", "0.0.0.0", "cccccccccccccccccccccccccccccccc"

    wip = Wip.new File.join(ENV["DAITSS_WORKSPACE"], ieid)

    wip.datafiles.each do |datafile|
      (["ateam.tiff", "ateam.xml"].include? datafile.metadata["sip-path"]).should == true
    end

    wip.metadata["sip-name"].should == "ateam"

    event_doc = LibXML::XML::Document.string wip.metadata["submit-event"]
    agent_doc = LibXML::XML::Document.string wip.metadata["submit-agent"]

    (event_doc.find_first "//xmlns:eventOutcome", "xmlns" => "info:lc/xmlns/premis-v2").content.should == "success"
    (event_doc.find_first "//xmlns:eventType", "xmlns" => "info:lc/xmlns/premis-v2").content.should == "submit"
    (event_doc.find_first "//xmlns:linkingObjectIdentifierValue", "xmlns" => "info:lc/xmlns/premis-v2").content.should == URI_PREFIX + ieid.to_s

    event_linking_agent = event_doc.find_first("//xmlns:linkingAgentIdentifierValue", "xmlns" => "info:lc/xmlns/premis-v2").content
    agent_identifier = agent_doc.find_first("//xmlns:agentIdentifierValue", "xmlns" => "info:lc/xmlns/premis-v2").content

    event_linking_agent.should == agent_identifier

    submission_event = OperationsEvent.all(:ieid => ieid, :event_name => "Package Submission").pop

    submission_event.ieid.should == ieid
    submission_event.event_name.should == "Package Submission"
    submission_event.timestamp.to_s.should == now.iso8601
    submission_event.operations_agent.identifier.should == "operator"
    submission_event.notes.should == "submitter_ip: 0.0.0.0, archive_type: tar, submitted_package_checksum: cccccccccccccccccccccccccccccccc"
  end

  it "should submit a package creating a wip with submission event from a zip-extracted SIP" do
    now = Time.now
    ieid = PackageSubmitter.submit_sip :zip, ZIP_SIP_NODIR, "ateam", "operator", "0.0.0.0", "cccccccccccccccccccccccccccccccc"

    wip = Wip.new File.join(ENV["DAITSS_WORKSPACE"], ieid.to_s)

    wip.datafiles.each do |datafile|
      (["ateam.tiff", "ateam.xml"].include? datafile.metadata["sip-path"]).should == true
    end

    wip.metadata["sip-name"].should == "ateam"

    event_doc = LibXML::XML::Document.string wip.metadata["submit-event"]
    agent_doc = LibXML::XML::Document.string wip.metadata["submit-agent"]

    (event_doc.find_first "//xmlns:eventOutcome", "xmlns" => "info:lc/xmlns/premis-v2").content.should == "success"
    (event_doc.find_first "//xmlns:eventType", "xmlns" => "info:lc/xmlns/premis-v2").content.should == "submit"
    (event_doc.find_first "//xmlns:linkingObjectIdentifierValue", "xmlns" => "info:lc/xmlns/premis-v2").content.should == URI_PREFIX + ieid.to_s

    event_linking_agent = event_doc.find_first("//xmlns:linkingAgentIdentifierValue", "xmlns" => "info:lc/xmlns/premis-v2").content
    agent_identifier = agent_doc.find_first("//xmlns:agentIdentifierValue", "xmlns" => "info:lc/xmlns/premis-v2").content

    event_linking_agent.should == agent_identifier

    submission_event = OperationsEvent.all(:ieid => ieid, :event_name => "Package Submission").pop

    submission_event.ieid.should == ieid
    submission_event.event_name.should == "Package Submission"
    submission_event.timestamp.to_s.should == now.iso8601
    submission_event.operations_agent.identifier.should == "operator"
    submission_event.notes.should == "submitter_ip: 0.0.0.0, archive_type: zip, submitted_package_checksum: cccccccccccccccccccccccccccccccc"
  end

  it "should raise error if descriptor cannot be found (package_name.xml)" do
    lambda { ieid = PackageSubmitter.submit_sip :zip, ZIP_NO_DESCRIPTOR, "ateam", "operator", "0.0.0.0", "cccccccccccccccccccccccccccccccc" }.should raise_error(DescriptorNotFoundError)
  end

  it "should raise error if descriptor cannot be parsed" do
    lambda { ieid = PackageSubmitter.submit_sip :zip, ZIP_BROKEN_DESCRIPTOR, "ateam", "operator", "0.0.0.0", "cccccccccccccccccccccccccccccccc" }.should raise_error(DescriptorCannotBeParsedError)
  end

  it "should extract descriptive metadata, if present" do
    ieid = PackageSubmitter.submit_sip :zip, ZIP_DMD_METADATA, "ateam", "operator", "0.0.0.0", "cccccccccccccccccccccccccccccccc"

    wip = Wip.new File.join(ENV["DAITSS_WORKSPACE"], ieid.to_s)

    wip.metadata["dmd-title"].should == "The (fd)A Team"
    wip.metadata["dmd-issue"].should == "2"
    wip.metadata["dmd-volume"].should == "1"
  end

  it "should extract FDA account/project if present" do
    ieid = PackageSubmitter.submit_sip :zip, ZIP_DMD_METADATA, "ateam", "operator", "0.0.0.0", "cccccccccccccccccccccccccccccccc"

    wip = Wip.new File.join(ENV["DAITSS_WORKSPACE"], ieid.to_s)

    wip.metadata["dmd-account"].should == "ACT"
    wip.metadata["dmd-project"].should == "PRJ"
  end

  it "should tolerate some missing DMD metadata" do
    ieid = PackageSubmitter.submit_sip :zip, ZIP_SIP_NODIR, "ateam", "operator", "0.0.0.0", "cccccccccccccccccccccccccccccccc"

    wip = Wip.new File.join(ENV["DAITSS_WORKSPACE"], ieid.to_s)

    wip.metadata["dmd-title"].should == "The (fd)A Team"
    wip.metadata["dmd-issue"].should == nil
    wip.metadata["dmd-volume"].should == nil
  end
end
