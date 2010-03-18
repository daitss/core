require 'package_submitter'
require 'fileutils'
require 'libxml'
require 'package_tracker'
require 'helper.rb'

describe PackageSubmitter do

  ZIP_SIP = "spec/test-sips/ateam.zip"
  TAR_SIP = "spec/test-sips/ateam.tar"
  ZIP_SIP_NODIR = "spec/test-sips/ateam-nodir.zip"
  TAR_SIP_NODIR = "spec/test-sips/ateam-nodir.tar"
  ZIP_NO_DESCRIPTOR = "spec/test-sips/ateam-nodesc.zip"
  ZIP_DMD_METADATA = "spec/test-sips/ateam-dmd.zip"
  ZIP_BROKEN_DESCRIPTOR = "spec/test-sips/ateam-broken-descriptor.zip"
  ZIP_WRONG_ACCOUNT = "spec/test-sips/ateam-wrong-account.zip"

  URI_PREFIX = "test:/"

  before(:each) do
    DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/data/submission_svc_test.db")
    DataMapper.auto_migrate!

    FileUtils.mkdir_p "/tmp/d2ws"
    ENV["WORKSPACE"] = "/tmp/d2ws"

    a = add_account "ACT", "ACT"
    add_operator a
    add_contact a, [], "foobar", "foobar"

    LibXML::XML.default_keep_blanks = false
  end

  after(:each) do
    FileUtils.rm_rf "/tmp/d2ws"
  end

  it "should raise error on create AIP from ZIP file if WORKSPACE is not set to a valid dir" do
    ENV["WORKSPACE"] = ""

    lambda { PackageSubmitter.submit_sip :zip, ZIP_SIP, "ateam", "0.0.0.0", "cccccccccccccccccccccccccccccccc" }.should raise_error
  end

  it "should raise error on create AIP from TAR file if WORKSPACE is not set to a valid dir" do
    ENV["WORKSPACE"] = ""

    lambda { PackageSubmitter.submit_sip :tar, TAR_SIP, "ateam", "0.0.0.0", "cccccccccccccccccccccccccccccccc" }.should raise_error
  end

  it "should generate a unique IEID for each AIP created" do
    ieid_1 = PackageSubmitter.submit_sip :zip, ZIP_SIP, "ateam", "operator", "0.0.0.0", "cccccccccccccccccccccccccccccccc" 
    ieid_2 = PackageSubmitter.submit_sip :tar, TAR_SIP, "ateam", "operator", "0.0.0.0", "cccccccccccccccccccccccccccccccc"

    ieid_1.should_not == ieid_2
  end

  it "should submit a package creating a wip with submission event from a tar-extracted SIP and a PT event" do
    ieid = PackageSubmitter.submit_sip :tar, TAR_SIP_NODIR, "ateam", "operator", "0.0.0.0", "cccccccccccccccccccccccccccccccc"
    now = Time.now

    wip = Wip.new File.join(ENV["WORKSPACE"], ieid)

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

    submission_event = OperationsEvent.first(:ieid => ieid, :event_name => "Package Submission")

    submission_event.ieid.should == ieid
    submission_event.event_name.should == "Package Submission"
    submission_event.timestamp.to_s.should == now.iso8601
    submission_event.operations_agent.identifier.should == "operator"
    submission_event.notes.should == "submitter_ip: 0.0.0.0, archive_type: tar, submitted_package_checksum: cccccccccccccccccccccccccccccccc"
  end

  it "should submit a package creating a wip with submission event from a zip-extracted SIP" do
    ieid = PackageSubmitter.submit_sip :zip, ZIP_SIP_NODIR, "ateam", "operator", "0.0.0.0", "cccccccccccccccccccccccccccccccc"
    now = Time.now

    wip = Wip.new File.join(ENV["WORKSPACE"], ieid.to_s)

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

    submission_event = OperationsEvent.first(:ieid => ieid, :event_name => "Package Submission")

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

  it "if there is an account specified in DMD metadata, then submission should create an agent for it" do
    ieid = PackageSubmitter.submit_sip :zip, ZIP_DMD_METADATA, "ateam", "operator", "0.0.0.0", "cccccccccccccccccccccccccccccccc"

    wip = Wip.new File.join(ENV["WORKSPACE"], ieid.to_s)


    event_doc = LibXML::XML::Document.string wip.metadata["submit-event"]
    agent_doc = LibXML::XML::Document.string wip.metadata["submit-agent-account"]

    agent_identifier = agent_doc.find_first("//xmlns:agentIdentifierValue", "xmlns" => "info:lc/xmlns/premis-v2").content

    agent_identifier.should == "info:fcla/daitss/accounts/ACT"

    # TODO: clean this up so that it's more readable
    # get an array with a string representation of the linkingAgentIdentifier nodes
    event_linking_agent_strings = event_doc.find("//xmlns:linkingAgentIdentifier", "xmlns" => "info:lc/xmlns/premis-v2").map {|node| node.children.to_s}

    event_linking_agent_strings.length.should == 2

    # check array for expected linkingAgentStrings: 1 for service, 1 for account
    (event_linking_agent_strings.include? "<linkingAgentIdentifierType>URI</linkingAgentIdentifierType><linkingAgentIdentifierValue>info:fcla/daitss/submission_service</linkingAgentIdentifierValue>").should == true
    (event_linking_agent_strings.include? "<linkingAgentIdentifierType>URI</linkingAgentIdentifierType><linkingAgentIdentifierValue>info:fcla/daitss/accounts/ACT</linkingAgentIdentifierValue>").should == true

  end

  it "should raise error if package account does not match submitter account" do
    lambda { ieid = PackageSubmitter.submit_sip :zip, ZIP_WRONG_ACCOUNT, "ateam", "operator", "0.0.0.0", "cccccccccccccccccccccccccccccccc" }.should raise_error(SubmitterDescriptorAccountMismatch)
  end
end
