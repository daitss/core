require 'package_submitter'
require 'fileutils'

describe PackageSubmitter do

  ZIP_SIP = "spec/test-sips/ateam.zip"
  TAR_SIP = "spec/test-sips/ateam.tar"
  ZIP_SIP_NODIR = "spec/test-sips/ateam-nodir.zip"
  TAR_SIP_NODIR = "spec/test-sips/ateam-nodir.tar"

  before(:each) do
    FileUtils.mkdir_p "/tmp/d2ws"
    ENV["DAITSS_WORKSPACE"] = "/tmp/d2ws"
  end

  after(:each) do
    #FileUtils.rm_rf "/tmp/d2ws"
  end

  it "should raise error on create AIP from ZIP file if DAITSS_WORKSPACE is not set to a valid dir" do
    ENV["DAITSS_WORKSPACE"] = ""
    PackageSubmitter.stub!(:generate_ieid).and_return true
    PackageSubmitter.stub!(:unzip_sip).and_return true

    lambda { PackageSubmitter.create_aip_from_zip ZIP_SIP }.should raise_error
  end

  it "should raise error on create AIP from TAR file if DAITSS_WORKSPACE is not set to a valid dir" do
    ENV["DAITSS_WORKSPACE"] = ""
    PackageSubmitter.stub!(:generate_ieid).and_return true
    PackageSubmitter.stub!(:unzip_sip).and_return true

    lambda { PackageSubmitter.create_aip_from_tar TAR_SIP }.should raise_error
  end

  it "should generate a unique IEID for each AIP created" do
    PackageSubmitter.stub!(:unzip_sip).and_return true
    PackageSubmitter.stub!(:untar_sip).and_return true

    ieid_1 = PackageSubmitter.create_aip_from_zip ZIP_SIP
    ieid_2 = PackageSubmitter.create_aip_from_tar TAR_SIP

    ieid_1.should_not == ieid_2
  end

  it "should unzip zipped AIP to temporary directory in DAITSS_WORKSPACE" do
    ieid = PackageSubmitter.create_aip_from_zip ZIP_SIP_NODIR

    File.exists?(File.join(ENV["DAITSS_WORKSPACE"], ".submit", "aip-#{ieid}", "ateam.tiff")).should == true
    File.exists?(File.join(ENV["DAITSS_WORKSPACE"], ".submit", "aip-#{ieid}", "ateam.xml")).should == true
  end

  it "should untar tarred AIP to temporary directory in DAITSS_WORKSPACE" do
    ieid = PackageSubmitter.create_aip_from_tar TAR_SIP_NODIR

    File.exists?(File.join(ENV["DAITSS_WORKSPACE"], ".submit", "aip-#{ieid}", "ateam.tiff")).should == true
    File.exists?(File.join(ENV["DAITSS_WORKSPACE"], ".submit", "aip-#{ieid}", "ateam.xml")).should == true
  end

  it "should unzip zipped AIP (with package in a directory) to temporary directory in DAITSS_WORKSPACE" do
    ieid = PackageSubmitter.create_aip_from_zip ZIP_SIP

    File.exists?(File.join(ENV["DAITSS_WORKSPACE"], ".submit", "aip-#{ieid}", "ateam.tiff")).should == true
    File.exists?(File.join(ENV["DAITSS_WORKSPACE"], ".submit", "aip-#{ieid}", "ateam.xml")).should == true
    File.exists?(File.join(ENV["DAITSS_WORKSPACE"], ".submit", "aip-#{ieid}", "ateam")).should_not == true
  end

  it "should unzip tarred AIP (with package in a directory) to temporary directory in DAITSS_WORKSPACE" do
    ieid = PackageSubmitter.create_aip_from_tar TAR_SIP

    File.exists?(File.join(ENV["DAITSS_WORKSPACE"], ".submit", "aip-#{ieid}", "ateam.tiff")).should == true
    File.exists?(File.join(ENV["DAITSS_WORKSPACE"], ".submit", "aip-#{ieid}", "ateam.xml")).should == true
    File.exists?(File.join(ENV["DAITSS_WORKSPACE"], ".submit", "aip-#{ieid}", "ateam")).should_not == true
  end

end
