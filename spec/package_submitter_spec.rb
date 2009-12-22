require 'package_submitter'
require 'fileutils'
require 'libxml'

describe PackageSubmitter do

  ZIP_SIP = "spec/test-sips/ateam.zip"
  TAR_SIP = "spec/test-sips/ateam.tar"
  ZIP_SIP_NODIR = "spec/test-sips/ateam-nodir.zip"
  TAR_SIP_NODIR = "spec/test-sips/ateam-nodir.tar"

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
    ieid_1 = PackageSubmitter.submit_sip :zip, ZIP_SIP, "ateam", "0.0.0.0", "cccccccccccccccccccccccccccccccc" 
    ieid_2 = PackageSubmitter.submit_sip :tar, TAR_SIP, "ateam", "0.0.0.0", "cccccccccccccccccccccccccccccccc"

    ieid_1.should_not == ieid_2
  end

  it "should submit a package creating a wip with submission event from a tar-extracted SIP" do
    ieid = PackageSubmitter.submit_sip :tar, TAR_SIP_NODIR, "ateam", "0.0.0.0", "cccccccccccccccccccccccccccccccc"

    wip = Wip.new File.join(ENV["DAITSS_WORKSPACE"], "wip-#{ieid}"), URI_PREFIX

    wip.datafiles.each do |datafile|
      (["ateam.tiff", "ateam.xml"].include? datafile.metadata["sip-path"]).should == true
    end

    wip.metadata["sip-name"].should == "ateam"

    event_doc = LibXML::XML::Document.string wip.metadata["submit-event"]
    agent_doc = LibXML::XML::Document.string wip.metadata["submit-agent"]

    (event_doc.find_first "//xmlns:eventOutcome", "xmlns" => "info:lc/xmlns/premis-v2").content.should == "success"
    (event_doc.find_first "//xmlns:eventType", "xmlns" => "info:lc/xmlns/premis-v2").content.should == "submit"
    (event_doc.find_first "//xmlns:linkingObjectIdentifierValue", "xmlns" => "info:lc/xmlns/premis-v2").content.should == URI_PREFIX + "wip-" + ieid.to_s

    event_linking_agent = event_doc.find_first("//xmlns:linkingAgentIdentifierValue", "xmlns" => "info:lc/xmlns/premis-v2").content
    agent_identifier = agent_doc.find_first("//xmlns:agentIdentifierValue", "xmlns" => "info:lc/xmlns/premis-v2").content

    event_linking_agent.should == agent_identifier
  end

  it "should submit a package creating a wip with submission event from a zip-extracted SIP" do
    ieid = PackageSubmitter.submit_sip :zip, ZIP_SIP_NODIR, "ateam", "0.0.0.0", "cccccccccccccccccccccccccccccccc"

    wip = Wip.new File.join(ENV["DAITSS_WORKSPACE"], "wip-#{ieid}"), URI_PREFIX

    wip.datafiles.each do |datafile|
      (["ateam.tiff", "ateam.xml"].include? datafile.metadata["sip-path"]).should == true
    end

    wip.metadata["sip-name"].should == "ateam"

    event_doc = LibXML::XML::Document.string wip.metadata["submit-event"]
    agent_doc = LibXML::XML::Document.string wip.metadata["submit-agent"]

    (event_doc.find_first "//xmlns:eventOutcome", "xmlns" => "info:lc/xmlns/premis-v2").content.should == "success"
    (event_doc.find_first "//xmlns:eventType", "xmlns" => "info:lc/xmlns/premis-v2").content.should == "submit"
    (event_doc.find_first "//xmlns:linkingObjectIdentifierValue", "xmlns" => "info:lc/xmlns/premis-v2").content.should == URI_PREFIX + "wip-" + ieid.to_s

    event_linking_agent = event_doc.find_first("//xmlns:linkingAgentIdentifierValue", "xmlns" => "info:lc/xmlns/premis-v2").content
    agent_identifier = agent_doc.find_first("//xmlns:agentIdentifierValue", "xmlns" => "info:lc/xmlns/premis-v2").content

    event_linking_agent.should == agent_identifier
  end
end
