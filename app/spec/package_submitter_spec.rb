require 'helper'

require 'package_submitter'
require 'fileutils'
require 'constants'
require 'daitss/config'

include Daitss

describe PackageSubmitter do

  before(:each) do
    CONFIG.load_from_env

    DataMapper.setup(:default, CONFIG['database-url'])
    DataMapper.auto_migrate!

    @workspace = Workspace.new CONFIG['workspace']

    a = add_account "ACT", "ACT"
    add_project a
    add_operator a
    add_contact a, [], "foobar", "foobar"

    b = add_account "UF", "UF"
    add_contact b, [], "bernie", "bernie"
    add_operator b, "op2", "op2"

    LibXML::XML.default_keep_blanks = false

    @ieid = rand(1000000).to_s
  end

  after(:each) do
    FileUtils.rm_rf File.join(@workspace.path, @ieid)
  end

  it "should create a success submission operations event for a good zipped sip" do
    ip_addr = "0.0.0.0"
    agent = OperationsAgent.first(:identifier => "operator")
    package_name = "ateam"
    package_path = ZIP_SIP

    PackageSubmitter.submit_sip @ieid, package_name, package_path, ip_addr, agent

    event = OperationsEvent.first(:submitted_sip => {:ieid => @ieid }, :event_name => "Package Submission")
    event.should_not be_nil
    event.notes.should =~ /outcome: success/
  end

  it "should put wip in workspace for a good zipped sip" do
    ip_addr = "0.0.0.0"
    agent = OperationsAgent.first(:identifier => "operator")
    package_name = "ateam"
    package_path = ZIP_SIP

    PackageSubmitter.submit_sip @ieid, package_name, package_path, ip_addr, agent

    wip = Wip.new File.join(@workspace.path, @ieid)
    wip.original_datafiles.length.should == 2
    wip["sip-name"].should == "ateam"
  end

  # TODO: make test more thorough by checking contents against an xpath
  it "should create submission premis metadata for a good zipped sip" do
    ip_addr = "0.0.0.0"
    agent = OperationsAgent.first(:identifier => "operator")
    package_name = "ateam"
    package_path = ZIP_SIP

    PackageSubmitter.submit_sip @ieid, package_name, package_path, ip_addr, agent

    wip = Wip.new File.join(@workspace.path, @ieid)

    wip["submit-agent"].should_not be_nil
    wip["submit-agent-account"].should_not be_nil
    wip["submit-event"].should_not be_nil
    wip["accept-event"].should_not be_nil
    wip["package-valid-event"].should_not be_nil
  end

  it "should associate submitted sip record with project for a good zipped sip" do
    ip_addr = "0.0.0.0"
    agent = OperationsAgent.first(:identifier => "operator")
    package_name = "ateam"
    package_path = ZIP_SIP

    PackageSubmitter.submit_sip @ieid, package_name, package_path, ip_addr, agent

    wip = Wip.new File.join(@workspace.path, @ieid)

    sip_record = SubmittedSip.first(:ieid => @ieid)
    sip_record.project.code.should == wip["dmd-project"]
  end

  it "should create a wip task for a good zipped sip" do
    ip_addr = "0.0.0.0"
    agent = OperationsAgent.first(:identifier => "operator")
    package_name = "ateam"
    package_path = ZIP_SIP

    PackageSubmitter.submit_sip @ieid, package_name, package_path, ip_addr, agent

    wip = Wip.new File.join(@workspace.path, @ieid)
    wip.task.should == :ingest
  end

  it "should reject SIPs missing a sip descriptor" do
    ip_addr = "0.0.0.0"
    agent = OperationsAgent.first(:identifier => "operator")
    package_name = "ateam"
    package_path = ZIP_NO_DESCRIPTOR

    lambda {PackageSubmitter.submit_sip @ieid, package_name, package_path, ip_addr, agent}.should raise_error(SipReject)

    event = OperationsEvent.first(:submitted_sip => {:ieid => @ieid }, :event_name => "Package Submission")
    event.should_not be_nil
    event.notes.should =~ /outcome: reject/
    event.notes.should =~ /failure reason: #{REJECT_DESCRIPTOR_NOT_FOUND}/

    File.directory?(File.join(PackageSubmitter::SUBMIT_WIP_DIR, @ieid)).should_not == true
  end

  it "should reject SIPs where the package is not in a directory named package_name (zip)" do
    ip_addr = "0.0.0.0"
    agent = OperationsAgent.first(:identifier => "operator")
    package_name = "ateam"
    package_path = ZIP_SIP_NODIR

    lambda {PackageSubmitter.submit_sip @ieid, package_name, package_path, ip_addr, agent}.should raise_error(SipReject)

    event = OperationsEvent.first(:submitted_sip => {:ieid => @ieid }, :event_name => "Package Submission")
    event.should_not be_nil
    event.notes.should =~ /outcome: reject/
    event.notes.should =~ /failure reason: #{REJECT_ARCHIVE_EXTRACTION_ERROR}/

    File.directory?(File.join(PackageSubmitter::SUBMIT_WIP_DIR, @ieid)).should_not == true
  end

  it "should reject SIPs where the package is not in a directory named package_name (tar)" do
    ip_addr = "0.0.0.0"
    agent = OperationsAgent.first(:identifier => "operator")
    package_name = "ateam"
    package_path = TAR_SIP_NODIR

    lambda {PackageSubmitter.submit_sip @ieid, package_name, package_path, ip_addr, agent}.should raise_error(SipReject)

    event = OperationsEvent.first(:submitted_sip => {:ieid => @ieid }, :event_name => "Package Submission")
    event.should_not be_nil
    event.notes.should =~ /outcome: reject/
    event.notes.should =~ /failure reason: #{REJECT_ARCHIVE_EXTRACTION_ERROR}/

    File.directory?(File.join(PackageSubmitter::SUBMIT_WIP_DIR, @ieid)).should_not == true
  end

  it "should reject SIPs where the SIP descriptor is not well formed" do
    ip_addr = "0.0.0.0"
    agent = OperationsAgent.first(:identifier => "operator")
    package_name = "ateam"
    package_path = ZIP_BROKEN_DESCRIPTOR

    lambda {PackageSubmitter.submit_sip @ieid, package_name, package_path, ip_addr, agent}.should raise_error(SipReject)

    event = OperationsEvent.first(:submitted_sip => {:ieid => @ieid }, :event_name => "Package Submission")
    event.should_not be_nil
    event.notes.should =~ /outcome: reject/
    event.notes.should =~ /failure reason: #{REJECT_INVALID_DESCRIPTOR}/

    File.directory?(File.join(PackageSubmitter::SUBMIT_WIP_DIR, @ieid)).should_not == true
  end

  it "should reject SIPs where the project specified is invalid" do
    ip_addr = "0.0.0.0"
    agent = OperationsAgent.first(:identifier => "operator")
    package_name = "ateam"
    package_path = ZIP_BAD_PROJECT

    lambda {PackageSubmitter.submit_sip @ieid, package_name, package_path, ip_addr, agent}.should raise_error(SipReject)

    event = OperationsEvent.first(:submitted_sip => {:ieid => @ieid }, :event_name => "Package Submission")
    event.should_not be_nil
    event.notes.should =~ /outcome: reject/
    event.notes.should =~ /failure reason: #{REJECT_INVALID_PROJECT}/

    File.directory?(File.join(PackageSubmitter::SUBMIT_WIP_DIR, @ieid)).should_not == true
  end

  it "should reject SIPs where the account specified is invalid" do
    ip_addr = "0.0.0.0"
    agent = OperationsAgent.first(:identifier => "operator")
    package_name = "ateam"
    package_path = ZIP_BAD_ACCOUNT

    lambda {PackageSubmitter.submit_sip @ieid, package_name, package_path, ip_addr, agent}.should raise_error(SipReject)

    event = OperationsEvent.first(:submitted_sip => {:ieid => @ieid }, :event_name => "Package Submission")
    event.should_not be_nil
    event.notes.should =~ /outcome: reject/
    event.notes.should =~ /failure reason: #{REJECT_INVALID_ACCOUNT}/

    File.directory?(File.join(PackageSubmitter::SUBMIT_WIP_DIR, @ieid)).should_not == true
  end

  it "should reject SIPs where there are no content files" do
    ip_addr = "0.0.0.0"
    agent = OperationsAgent.first(:identifier => "operator")
    package_name = "ateam"
    package_path = ZIP_NO_CONTENT_FILES

    lambda {PackageSubmitter.submit_sip @ieid, package_name, package_path, ip_addr, agent}.should raise_error(SipReject)

    event = OperationsEvent.first(:submitted_sip => {:ieid => @ieid }, :event_name => "Package Submission")
    event.should_not be_nil
    event.notes.should =~ /outcome: reject/
    event.notes.should =~ /failure reason: #{REJECT_MISSING_CONTENT_FILE}/

    File.directory?(File.join(PackageSubmitter::SUBMIT_WIP_DIR, @ieid)).should_not == true
  end

  it "should reject SIPs when there is a checksum mismatch between sip files and descriptor" do
    ip_addr = "0.0.0.0"
    agent = OperationsAgent.first(:identifier => "operator")
    package_name = "ateam"
    package_path = ZIP_CHECKSUM_MISMATCH

    lambda {PackageSubmitter.submit_sip @ieid, package_name, package_path, ip_addr, agent}.should raise_error(SipReject)

    event = OperationsEvent.first(:submitted_sip => {:ieid => @ieid }, :event_name => "Package Submission")
    event.should_not be_nil
    event.notes.should =~ /outcome: reject/
    event.notes.should =~ /failure reason: #{REJECT_CHECKSUM_MISMATCH}/

    File.directory?(File.join(PackageSubmitter::SUBMIT_WIP_DIR, @ieid)).should_not == true
  end

  it "should reject SIPs when it is not a valid zip or tar archive" do
    ip_addr = "0.0.0.0"
    agent = OperationsAgent.first(:identifier => "operator")
    package_name = "ateam"
    package_path = NOT_VALID_ARCHIVE

    lambda {PackageSubmitter.submit_sip @ieid, package_name, package_path, ip_addr, agent}.should raise_error(SipReject)

    event = OperationsEvent.first(:submitted_sip => {:ieid => @ieid }, :event_name => "Package Submission")
    event.should_not be_nil
    event.notes.should =~ /outcome: reject/
    event.notes.should =~ /failure reason: #{REJECT_ARCHIVE_EXTRACTION_ERROR}/

    File.directory?(File.join(PackageSubmitter::SUBMIT_WIP_DIR, @ieid)).should_not == true
  end

  it "should reject SIPs when the sip descriptor is invalid" do
    ip_addr = "0.0.0.0"
    agent = OperationsAgent.first(:identifier => "operator")
    package_name = "ateam"
    package_path = ZIP_INVALID_DESCRIPTOR

    lambda {PackageSubmitter.submit_sip @ieid, package_name, package_path, ip_addr, agent}.should raise_error(SipReject)

    event = OperationsEvent.first(:submitted_sip => {:ieid => @ieid }, :event_name => "Package Submission")
    event.should_not be_nil
    event.notes.should =~ /outcome: reject/
    event.notes.should =~ /failure reason: #{REJECT_INVALID_DESCRIPTOR}/

    File.directory?(File.join(PackageSubmitter::SUBMIT_WIP_DIR, @ieid)).should_not == true
  end

  it "should reject SIPs when content files are present, but none are described" do
    pending 'Wip#from_sip handles this, refactor logic!'
    ip_addr = "0.0.0.0"
    agent = OperationsAgent.first(:identifier => "operator")
    package_name = "ateam"
    package_path = ZIP_NO_DESCRIBED_CONTENT_FILE

    lambda {PackageSubmitter.submit_sip @ieid, package_name, package_path, ip_addr, agent}.should raise_error(SipReject)

    event = OperationsEvent.first(:submitted_sip => {:ieid => @ieid }, :event_name => "Package Submission")
    event.should_not be_nil
    event.notes.should =~ /outcome: reject/
    event.notes.should =~ /failure reason: #{REJECT_MISSING_CONTENT_FILE}/

    File.directory?(File.join(PackageSubmitter::SUBMIT_WIP_DIR, @ieid)).should_not == true
  end

  it "should reject SIPs when the package name is too long" do
    ip_addr = "0.0.0.0"
    agent = OperationsAgent.first(:identifier => "operator")
    package_name = "ateam123456789012345678901234567890"
    package_path = ZIP_LONG_PACKAGE_NAME

    lambda {PackageSubmitter.submit_sip @ieid, package_name, package_path, ip_addr, agent}.should raise_error(SipReject)

    event = OperationsEvent.first(:submitted_sip => {:ieid => @ieid }, :event_name => "Package Submission")
    event.should_not be_nil
    event.notes.should =~ /outcome: reject/
    event.notes.should =~ /failure reason: #{REJECT_INVALID_PACKAGE_NAME}/

    File.directory?(File.join(PackageSubmitter::SUBMIT_WIP_DIR, @ieid)).should_not == true
  end

  it "should reject SIPs when the package name has invalid characters" do
    ip_addr = "0.0.0.0"
    agent = OperationsAgent.first(:identifier => "operator")
    package_name = "a'team"
    package_path = ZIP_INVALID_CHAR_IN_NAME

    lambda {PackageSubmitter.submit_sip @ieid, package_name, package_path, ip_addr, agent}.should raise_error(SipReject)

    event = OperationsEvent.first(:submitted_sip => {:ieid => @ieid }, :event_name => "Package Submission")
    event.should_not be_nil
    event.notes.should =~ /outcome: reject/
    event.notes.should =~ /failure reason: #{REJECT_INVALID_PACKAGE_NAME}/

    File.directory?(File.join(PackageSubmitter::SUBMIT_WIP_DIR, @ieid)).should_not == true
  end

  it "should reject SIPs if submitted by a contact from a different account" do
    ip_addr = "0.0.0.0"
    agent = OperationsAgent.first(:identifier => "bernie")
    package_name = "ateam"
    package_path = ZIP_SIP

    lambda {PackageSubmitter.submit_sip @ieid, package_name, package_path, ip_addr, agent}.should raise_error(SipReject)

    event = OperationsEvent.first(:submitted_sip => {:ieid => @ieid }, :event_name => "Package Submission")
    event.should_not be_nil
    event.notes.should =~ /outcome: reject/
    event.notes.should =~ /failure reason: #{REJECT_SUBMITTER_DESCRIPTOR_ACCOUNT_MISMATCH}/

    File.directory?(File.join(PackageSubmitter::SUBMIT_WIP_DIR, @ieid)).should_not == true
  end

  it "should reject SIPs if datafile present with invalid name" do
    ip_addr = "0.0.0.0"
    agent = OperationsAgent.first(:identifier => "operator")
    package_name = "ateam"
    package_path = ZIP_INVALID_DATAFILE_NAME

    lambda {PackageSubmitter.submit_sip @ieid, package_name, package_path, ip_addr, agent}.should raise_error(SipReject)

    event = OperationsEvent.first(:submitted_sip => {:ieid => @ieid }, :event_name => "Package Submission")
    event.should_not be_nil
    event.notes.should =~ /outcome: reject/
    event.notes.should =~ /failure reason: #{REJECT_INVALID_DATAFILE_NAME}/

    File.directory?(File.join(PackageSubmitter::SUBMIT_WIP_DIR, @ieid)).should_not == true
  end

  it "should reject and correcly detect SIP with multiple validation problems" do
    ip_addr = "0.0.0.0"
    agent = OperationsAgent.first(:identifier => "operator")
    package_name = "ateam"
    package_path = ZIP_MULTIPLE_PROBLEMS

    lambda {PackageSubmitter.submit_sip @ieid, package_name, package_path, ip_addr, agent}.should raise_error(SipReject)

    event = OperationsEvent.first(:submitted_sip => {:ieid => @ieid }, :event_name => "Package Submission")
    event.should_not be_nil
    event.notes.should =~ /outcome: reject/
    event.notes.should =~ /failure reason: #{REJECT_INVALID_DATAFILE_NAME}/
    event.notes.should =~ /failure reason: #{REJECT_CHECKSUM_MISMATCH}/
    event.notes.should =~ /failure reason: #{REJECT_INVALID_PROJECT}/

    File.directory?(File.join(PackageSubmitter::SUBMIT_WIP_DIR, @ieid)).should_not == true
  end

  it "should not reject SIPs when file checksums are missing from descriptor" do
    ip_addr = "0.0.0.0"
    agent = OperationsAgent.first(:identifier => "operator")
    package_name = "ateam"
    package_path = ZIP_MISSING_CHECKSUM

    lambda {PackageSubmitter.submit_sip @ieid, package_name, package_path, ip_addr, agent}.should_not raise_error

    event = OperationsEvent.first(:submitted_sip => {:ieid => @ieid }, :event_name => "Package Submission")
    event.should_not be_nil
    event.notes.should =~ /outcome: success/
  end

  it "should not reject SIPs when file checksum type in descriptor is unknown" do
    ip_addr = "0.0.0.0"
    agent = OperationsAgent.first(:identifier => "operator")
    package_name = "ateam"
    package_path = ZIP_UNKNOWN_CHECKSUM_TYPE

    lambda {PackageSubmitter.submit_sip @ieid, package_name, package_path, ip_addr, agent}.should_not raise_error

    event = OperationsEvent.first(:submitted_sip => {:ieid => @ieid }, :event_name => "Package Submission")
    event.should_not be_nil
    event.notes.should =~ /outcome: success/
  end

  it "should not reject SIPs when submitted by an operator with a different account" do
    ip_addr = "0.0.0.0"
    agent = OperationsAgent.first(:identifier => "op2")
    package_name = "ateam"
    package_path = ZIP_SIP

    lambda {PackageSubmitter.submit_sip @ieid, package_name, package_path, ip_addr, agent}.should_not raise_error

    event = OperationsEvent.first(:submitted_sip => {:ieid => @ieid }, :event_name => "Package Submission")
    event.should_not be_nil
    event.notes.should =~ /outcome: success/
  end
end
