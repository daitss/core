require 'sip/from_archive'
require 'daitss/config'
require 'pp'

REPO_ROOT = File.join File.dirname(__FILE__), ".."
ZIP_SIP = File.join(REPO_ROOT, "spec", "test-sips", "ateam.zip")
TAR_SIP = File.join(REPO_ROOT, "spec", "test-sips", "ateam.tar")
NO_SIP_DESCRIPTOR = File.join(REPO_ROOT, "spec", "test-sips", "ateam-nodesc.zip")
NO_DIR = File.join(REPO_ROOT, "spec", "test-sips", "ateam-nodir.zip")
NOT_AN_ARCHIVE = File.join(REPO_ROOT, "spec", "test-sips", "not-an-archive")

describe Sip do

  before(:each) do
    Daitss::CONFIG.load_from_env

    DataMapper.setup(:default, Daitss::CONFIG['database-url'])
    #DataMapper.auto_migrate!
  end

  it "should create sip from zip file" do
    ieid = rand(1000)
    sip = Sip.from_archive ZIP_SIP, ieid, "ateam"

    File.directory?(sip.path).should == true

    sip.files.length.should == 2
    sip.files.include?("ateam.tiff").should == true
    sip.files.include?("ateam.xml").should == true
  end

  it "should create sip from tar file" do
    ieid = rand(1000)
    sip = Sip.from_archive TAR_SIP, ieid, "ateam"

    File.directory?(sip.path).should == true

    sip.files.length.should == 2
    sip.files.include?("ateam.tiff").should == true
    sip.files.include?("ateam.xml").should == true
  end

  it "should create a complete submitted sip record for successfully extracted sip" do
    ieid = rand(1000)
    sip = Sip.from_archive ZIP_SIP, ieid, "ateam"

    sip_record = SubmittedSip.first(:ieid => ieid)

    sip_record.package_name.should == "ateam"
    sip_record.package_size.should == 923328
    sip_record.number_of_datafiles.should == 2
  end

  it "should raise error and create sip record if sip descriptor is not found" do
    ieid = rand(1000)

    lambda { sip = Sip.from_archive NO_SIP_DESCRIPTOR, ieid, "ateam" }.should raise_error(DescriptorNotFoundError)

    sip_record = SubmittedSip.first(:ieid => ieid)

    sip_record.package_name.should == "ateam"
    sip_record.package_size.should_not be_nil
    sip_record.number_of_datafiles.should == 1
  end

  it "should raise error and create sip record if sip is not archived in directory named package name" do
    ieid = rand(1000)

    lambda { sip = Sip.from_archive NO_DIR, ieid, "ateam" }.should raise_error(ArchiveExtractionError)

    sip_record = SubmittedSip.first(:ieid => ieid)

    sip_record.package_name.should == "ateam"
    sip_record.package_size.should == nil
    sip_record.number_of_datafiles.should == nil
  end 

  it "should raise error and create sip record if archive cannot be extracted" do 
    ieid = rand(1000)

    lambda { sip = Sip.from_archive NOT_AN_ARCHIVE, ieid, "ateam" }.should raise_error(ArchiveExtractionError)

    sip_record = SubmittedSip.first(:ieid => ieid)

    sip_record.package_name.should == "ateam"
    sip_record.package_size.should == nil
    sip_record.number_of_datafiles.should == nil
  end
end
