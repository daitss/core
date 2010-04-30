require 'package_submitter'
require 'fileutils'
require 'libxml'
require 'package_tracker'
require 'helper.rb'
require 'old_ieid'

describe PackageSubmitter do

  ZIP_SIP = "spec/test-sips/ateam.zip"
  TAR_SIP = "spec/test-sips/ateam.tar"
  ZIP_SIP_NODIR = "spec/test-sips/ateam-nodir.zip"
  TAR_SIP_NODIR = "spec/test-sips/ateam-nodir.tar"
  ZIP_NO_DESCRIPTOR = "spec/test-sips/ateam-nodesc.zip"
  ZIP_DMD_METADATA = "spec/test-sips/ateam-dmd.zip"
  ZIP_BROKEN_DESCRIPTOR = "spec/test-sips/ateam-broken-descriptor.zip"
  ZIP_BAD_PROJECT = "spec/test-sips/ateam-bad-project"
  ZIP_BAD_ACCOUNT = "spec/test-sips/ateam-bad-account"
  ZIP_NO_CONTENT_FILES = "spec/test-sips/ateam-missing-contentfile.zip"
  ZIP_CHECKSUM_MISMATCH = "spec/test-sips/ateam-checksum-mismatch.zip"
  ZIP_INVALID_DESCRIPTOR = "spec/test-sips/ateam-invalid-descriptor.zip"

  URI_PREFIX = "test:/"

  before(:each) do
    DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/data/submission_svc_test.db")
    DataMapper.auto_migrate!

    FileUtils.mkdir_p "/tmp/d2ws"
    ENV["WORKSPACE"] = "/tmp/d2ws"

    a = add_account "ACT", "ACT"
    add_project a
    add_operator a
    add_contact a, [], "foobar", "foobar"

    b = add_account "UF", "UF"
    add_contact b, [], "bernie", "bernie"

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

  it "should submit a package creating a wip with submission event from a tar-extracted SIP, a PT event, submit step, and a new row in the sip table" do
    ieid = OldIeid.get_next
    PackageSubmitter.submit_sip :tar, TAR_SIP_NODIR, "ateam", "operator", "0.0.0.0", "cccccccccccccccccccccccccccccccc", ieid
    now = Time.now

    wip = Wip.new File.join(ENV["WORKSPACE"], ieid)

    wip.original_datafiles.each do |datafile|
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
    submission_event.timestamp.to_time.should be_close(now, 1.0)
    submission_event.operations_agent.identifier.should == "operator"
    submission_event.notes.should == "submitter_ip: 0.0.0.0, archive_type: tar, submitted_package_checksum: cccccccccccccccccccccccccccccccc, outcome: success"
    File.exists?(File.join(ENV["WORKSPACE"], ieid, "tags", "task")).should == true
    File.read(File.join(ENV["WORKSPACE"], ieid, "tags", "task")).should == "ingest"

    sip = SubmittedSip.first(:ieid => ieid)

    sip.should_not be_nil
    sip.package_name.should == "ateam"
    sip.package_size.should == 923328
    sip.number_of_datafiles.should == 2
  end

  it "should submit a package creating a wip with submission event from a zip-extracted SIP" do
    ieid = OldIeid.get_next
    PackageSubmitter.submit_sip :zip, ZIP_SIP_NODIR, "ateam", "operator", "0.0.0.0", "cccccccccccccccccccccccccccccccc", ieid
    now = Time.now

    wip = Wip.new File.join(ENV["WORKSPACE"], ieid.to_s)

    wip.original_datafiles.each do |datafile|
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
    submission_event.timestamp.to_time.should be_close(now, 1.0)
    submission_event.operations_agent.identifier.should == "operator"
    submission_event.notes.should == "submitter_ip: 0.0.0.0, archive_type: zip, submitted_package_checksum: cccccccccccccccccccccccccccccccc, outcome: success"

    File.exists?(File.join(ENV["WORKSPACE"], ieid, "tags", "task")).should == true
    File.read(File.join(ENV["WORKSPACE"], ieid, "tags", "task")).should == "ingest"

    sip = SubmittedSip.first(:ieid => ieid)

    sip.should_not be_nil
    sip.package_name.should == "ateam"
    sip.package_size.should == 923328
    sip.number_of_datafiles.should == 2
  end

  it "should raise error if descriptor cannot be found (package_name.xml)" do
    ieid = OldIeid.get_next
    now = Time.now

    lambda { PackageSubmitter.submit_sip :zip, ZIP_NO_DESCRIPTOR, "ateam", "operator", "0.0.0.0", "cccccccccccccccccccccccccccccccc", ieid }.should raise_error(DescriptorNotFoundError)

    submission_event = OperationsEvent.first(:ieid => ieid, :event_name => "Package Submission")

    submission_event.ieid.should == ieid
    submission_event.event_name.should == "Package Submission"
    submission_event.timestamp.to_time.should be_close(now, 1.0)
    submission_event.operations_agent.identifier.should == "operator"
    submission_event.notes.should == "submitter_ip: 0.0.0.0, archive_type: zip, submitted_package_checksum: cccccccccccccccccccccccccccccccc, outcome: failure, failure_reason: descriptor not found"
  end

  it "should raise error if descriptor cannot be parsed" do
    ieid = OldIeid.get_next
    now = Time.now

    lambda { PackageSubmitter.submit_sip :zip, ZIP_BROKEN_DESCRIPTOR, "ateam", "operator", "0.0.0.0", "cccccccccccccccccccccccccccccccc", ieid }.should raise_error(DescriptorCannotBeParsedError)

    submission_event = OperationsEvent.first(:ieid => ieid, :event_name => "Package Submission")

    submission_event.ieid.should == ieid
    submission_event.event_name.should == "Package Submission"
    submission_event.timestamp.to_time.should be_close(now, 1.0)
    submission_event.operations_agent.identifier.should == "operator"
    submission_event.notes.should == "submitter_ip: 0.0.0.0, archive_type: zip, submitted_package_checksum: cccccccccccccccccccccccccccccccc, outcome: failure, failure_reason: descriptor cannot be parsed"
  end

  it "if there is an account specified in DMD metadata, then submission should create an agent for it" do
    ieid = OldIeid.get_next
    PackageSubmitter.submit_sip :zip, ZIP_DMD_METADATA, "ateam", "operator", "0.0.0.0", "cccccccccccccccccccccccccccccccc", ieid

    wip = Wip.new File.join(ENV["WORKSPACE"], ieid.to_s)


    event_doc = LibXML::XML::Document.string wip.metadata["submit-event"]
    agent_doc = LibXML::XML::Document.string wip.metadata["submit-agent-account"]

    agent_identifier = agent_doc.find_first("//xmlns:agentIdentifierValue", "xmlns" => "info:lc/xmlns/premis-v2").content

    agent_identifier.should == "info:fda/daitss/accounts/ACT"

    # TODO: clean this up so that it's more readable
    # get an array with a string representation of the linkingAgentIdentifier nodes
    event_linking_agent_strings = event_doc.find("//xmlns:linkingAgentIdentifier", "xmlns" => "info:lc/xmlns/premis-v2").map {|node| node.children.to_s}

    event_linking_agent_strings.length.should == 2

    # check array for expected linkingAgentStrings: 1 for service, 1 for account
    (event_linking_agent_strings.include? "<linkingAgentIdentifierType>URI</linkingAgentIdentifierType><linkingAgentIdentifierValue>info:fda/daitss/submission_service</linkingAgentIdentifierValue>").should == true
    (event_linking_agent_strings.include? "<linkingAgentIdentifierType>URI</linkingAgentIdentifierType><linkingAgentIdentifierValue>info:fda/daitss/accounts/ACT</linkingAgentIdentifierValue>").should == true

  end

  it "should raise error if package account does not match submitter account" do
    ieid = OldIeid.get_next
    now = Time.now

    lambda { PackageSubmitter.submit_sip :zip, ZIP_SIP, "ateam", "bernie", "0.0.0.0", "cccccccccccccccccccccccccccccccc", ieid }.should raise_error(SubmitterDescriptorAccountMismatch)

    submission_event = OperationsEvent.first(:ieid => ieid, :event_name => "Package Submission")

    submission_event.ieid.should == ieid
    submission_event.event_name.should == "Package Submission"
    submission_event.timestamp.to_time.should be_close(now, 5.0)
    submission_event.operations_agent.identifier.should == "bernie"
    submission_event.notes.should == "submitter_ip: 0.0.0.0, archive_type: zip, submitted_package_checksum: cccccccccccccccccccccccccccccccc, outcome: failure, failure_reason: submitter account does not match descriptor"
  end

  it "should raise error if the package project is invalid - operator" do
    ieid = OldIeid.get_next
    now = Time.now

    lambda { PackageSubmitter.submit_sip :zip, ZIP_BAD_PROJECT, "ateam", "operator", "0.0.0.0", "cccccccccccccccccccccccccccccccc", ieid }.should raise_error(InvalidProject)

    submission_event = OperationsEvent.first(:ieid => ieid, :event_name => "Package Submission")

    submission_event.ieid.should == ieid
    submission_event.event_name.should == "Package Submission"
    submission_event.timestamp.to_time.should be_close(now, 5.0)
    submission_event.operations_agent.identifier.should == "operator"
    submission_event.notes.should == "submitter_ip: 0.0.0.0, archive_type: zip, submitted_package_checksum: cccccccccccccccccccccccccccccccc, outcome: failure, failure_reason: invalid project"
  end

  it "should raise error if the package project is invalid - contact" do
    ieid = OldIeid.get_next
    now = Time.now

    lambda { PackageSubmitter.submit_sip :zip, ZIP_BAD_PROJECT, "ateam", "foobar", "0.0.0.0", "cccccccccccccccccccccccccccccccc", ieid }.should raise_error(InvalidProject)

    submission_event = OperationsEvent.first(:ieid => ieid, :event_name => "Package Submission")

    submission_event.ieid.should == ieid
    submission_event.event_name.should == "Package Submission"
    submission_event.timestamp.to_time.should be_close(now, 5.0)
    submission_event.operations_agent.identifier.should == "foobar"
    submission_event.notes.should == "submitter_ip: 0.0.0.0, archive_type: zip, submitted_package_checksum: cccccccccccccccccccccccccccccccc, outcome: failure, failure_reason: invalid project"
  end

  it "should raise error if the package account is invalid - operator" do
    ieid = OldIeid.get_next
    now = Time.now

    lambda { PackageSubmitter.submit_sip :zip, ZIP_BAD_ACCOUNT, "ateam", "operator", "0.0.0.0", "cccccccccccccccccccccccccccccccc", ieid }.should raise_error(InvalidAccount)

    submission_event = OperationsEvent.first(:ieid => ieid, :event_name => "Package Submission")

    submission_event.ieid.should == ieid
    submission_event.event_name.should == "Package Submission"
    submission_event.timestamp.to_time.should be_close(now, 5.0)
    submission_event.operations_agent.identifier.should == "operator"
    submission_event.notes.should == "submitter_ip: 0.0.0.0, archive_type: zip, submitted_package_checksum: cccccccccccccccccccccccccccccccc, outcome: failure, failure_reason: invalid account"
  end

  it "should raise error if the package does not have at least one content file" do
    ieid = OldIeid.get_next
    now = Time.now

    lambda { PackageSubmitter.submit_sip :zip, ZIP_NO_CONTENT_FILES, "ateam", "foobar", "0.0.0.0", "cccccccccccccccccccccccccccccccc", ieid }.should raise_error(MissingContentFile)

    submission_event = OperationsEvent.first(:ieid => ieid, :event_name => "Package Submission")

    submission_event.ieid.should == ieid
    submission_event.event_name.should == "Package Submission"
    submission_event.timestamp.to_time.should be_close(now, 5.0)
    submission_event.operations_agent.identifier.should == "foobar"
    submission_event.notes.should == "submitter_ip: 0.0.0.0, archive_type: zip, submitted_package_checksum: cccccccccccccccccccccccccccccccc, outcome: failure, failure_reason: content file not found"
  end

  it "should raise error if there is a checksum mismatch between the descriptor any data file and record the reject in pt" do
    ieid = OldIeid.get_next
    now = Time.now

    lambda { PackageSubmitter.submit_sip :zip, ZIP_CHECKSUM_MISMATCH, "ateam", "foobar", "0.0.0.0", "cccccccccccccccccccccccccccccccc", ieid }.should raise_error(ChecksumMismatch)

    submission_event = OperationsEvent.first(:ieid => ieid, :event_name => "Package Submission")

    submission_event.ieid.should == ieid
    submission_event.event_name.should == "Package Submission"
    submission_event.timestamp.to_time.should be_close(now, 5.0)
    submission_event.operations_agent.identifier.should == "foobar"
    submission_event.notes.should == "submitter_ip: 0.0.0.0, archive_type: zip, submitted_package_checksum: cccccccccccccccccccccccccccccccc, outcome: failure, failure_reason: datafile failed checksum check against descriptor"
  end

  it "should raise error if there is an error validating the sip descriptor and record the reject in pt" do
    ieid = OldIeid.get_next
    now = Time.now

    lambda { PackageSubmitter.submit_sip :zip, ZIP_INVALID_DESCRIPTOR, "ateam", "foobar", "0.0.0.0", "cccccccccccccccccccccccccccccccc", ieid }.should raise_error(InvalidDescriptor)

    submission_event = OperationsEvent.first(:ieid => ieid, :event_name => "Package Submission")

    submission_event.ieid.should == ieid
    submission_event.event_name.should == "Package Submission"
    submission_event.timestamp.to_time.should be_close(now, 5.0)
    submission_event.operations_agent.identifier.should == "foobar"
    submission_event.notes.should =~ /submitter_ip: 0.0.0.0, archive_type: zip, submitted_package_checksum: cccccccccccccccccccccccccccccccc, outcome: failure, failure_reason: descriptor failed validation/
  end
end
