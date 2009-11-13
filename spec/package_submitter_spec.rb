require 'package_submitter'
require 'fileutils'

describe PackageSubmitter do

  ZIP_SIP = "spec/test-sips/ateam.zip"
  TAR_SIP = "spec/test-sips/ateam.tar"

  before(:each) do
    FileUtils.mkdir_p "/tmp/d2ws"
    ENV["DAITSS_WORKSPACE"] = "/tmp/d2ws"
  end

  after(:each) do
    FileUtils.rm_rf "/tmp/d2ws"
  end

  it "should raise error on create AIP from ZIP file if DAITSS_WORKSPACE is not set to a valid dir" do
    ENV["DAITSS_WORKSPACE"] = ""
    lambda { PackageSubmitter.create_aip_from_zip ZIP_SIP }.should raise_error
  end

  it "should raise error on create AIP from TAR file if DAITSS_WORKSPACE is not set to a valid dir" do
    ENV["DAITSS_WORKSPACE"] = ""
    lambda { PackageSubmitter.create_aip_from_tar TAR_SIP }.should raise_error
  end

  it "should generate a unique IEID for each AIP created" do
    ieid_1 = PackageSubmitter.create_aip_from_zip ZIP_SIP
    ieid_2 = PackageSubmitter.create_aip_from_tar TAR_SIP

    ieid_1.should_not == ieid_2
  end

  #it "should unzip zipped AIP to temporary directory in DAITSS_WORKSPACE" do
    #PackageSubmitter.create_aip_from_zip ZIP_SIP
#
    #File.directory? File.join(ENV["DAITSS_WORKSPACE"], .submit).should == true
    #File.directory? File.join(ENV["DAITSS_WORKSPACE"], .submit).should == true
  #end

    #puts File.exists? ZIP_SIP
    #puts File.exists? TAR_SIP
end
