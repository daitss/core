require 'daitss/proc/sip_archive'

describe SipArchive do

  it "should be an error if the package name is too long" do
    path = new_sip_archive 'very-long-name-0123456789abcdefABCDEF.zip'
    sa = SipArchive.new path
    sa.should_not be_valid
    sa.errors.should include("package name contains too many characters (37) max is 32")
  end

  it "should be an error if the package name is contains invalid characters" do
    path = new_sip_archive %q{.bad '" names 1 2 3 4 5 6 7 8 9 a b c d e f.zip}
    lambda { SipArchive.new path }.should raise_error("invalid characters in sip name")
  end

  it "should raise error and create sip record if archive cannot be extracted" do
    path = new_sip_archive 'not-an-archive.zip'
    lambda { SipArchive.new path }.should raise_error(/^error extracting not-an-archive\.zip/)
  end

  it 'should raise an error if the archive type is unknown' do
    path = new_sip_archive 'haskell-nums-pdf.jar'
    lambda { SipArchive.new path }.should raise_error('unknown archive extension: .jar')
  end

  it 'should raise an error if the extraction does not result in a directory' do
    path = new_sip_archive 'not-a-package.zip'
    lambda { SipArchive.new path }.should raise_error("not-a-package.zip is not a package")
  end

  it "should create sip from zip file" do
    path = new_sip_archive 'haskell-nums-pdf.zip'
    lambda { SipArchive.new path }.should_not raise_error
  end

  it "should create sip from tar file" do
    path = new_sip_archive 'haskell-nums-pdf.tar'
    lambda { SipArchive.new path }.should_not raise_error
  end

  it "should be invalid and contain an error if descriptor is not found" do
    path = new_sip_archive 'missing-descriptor.zip'
    sa = SipArchive.new path
    sa.should_not be_valid
    sa.errors.should include('missing descriptor')
  end

  it "should be invalid and contain an error is the descriptor is invalid" do
    path = new_sip_archive 'invalid-descriptor.zip'
    sa = SipArchive.new path
    sa.should_not be_valid
    sa.errors.should include("invalid descriptor")
    sa.errors.should include(%q{44: cvc-complex-type.2.3: Element 'structMap' cannot have character [children], because the type's content type is element-only.})
    sa.errors.should include(%q{44: cvc-complex-type.2.4.b: The content of element 'structMap' is not complete. One of '{"http://www.loc.gov/METS/":div}' is expected.})
  end


  it "should be invalid and contain an error for every content file with an invalid checksum" do
    path = new_sip_archive 'bad-checksum.zip'
    sa = SipArchive.new path
    sa.should_not be_valid
    sa.errors.should include("SHA-1 for Haskell98numbers.pdf:\n  expected: aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\n  computed: d20d46494e5145f68b6e9938a9bbd80d36d28c69\n")
  end

  it "should be invalid and contain an error if there are no content files" do
    path = new_sip_archive 'missing-content-files.zip'
    sa = SipArchive.new path
    sa.should_not be_valid
    sa.errors.should include('missing content files')
  end

  it "should be invalid and contain errors if any files have invalid names" do
    path = new_sip_archive 'bad-file-names.zip'
    sa = SipArchive.new path
    sa.should_not be_valid
    sa.errors.should include("invalid characters in file name: .bad ' file")
    sa.errors.should include("invalid characters in file name: .bad \" file")
  end

  describe 'descriptive metadata' do

    before :all do
      @sa = SipArchive.new new_sip_archive('haskell-nums-pdf.zip')
    end

    it 'should provide sip descriptor' do
      @sa.descriptor_doc.to_s.should_not be_empty
    end

    it 'should provide account' do
      @sa.account.should == 'ACT'
    end

    it 'should provide project' do
      @sa.project.should == 'PRJ'
    end

    it 'should provide title' do
      @sa.title.should == 'Haskell Numbers'
    end

    it 'should provide volume' do
      @sa.volume.should == '1'
    end

    it 'should provide issue' do
      @sa.issue.should == '2'
    end

    it 'should provide entity id' do
      @sa.entity_id.should == 'haskell-nums-pdf'
    end

  end

  describe 'issue volume title' do

    it "should correctly process OJS descriptor 1" do
      path = new_sip_archive 'haskell-nums-pdf.zip'
      s = SipArchive.new path

      s.stub!(:descriptor_doc).and_return(XML::Document.string File.read(File.join(DESCRIPTOR_DIR, "OJStest6.xml")))

      ivt = s.issue_vol_title

      ivt["title"].should == "IEICE Transactions on Fundamentals of Electronics, Communications and Computer Sciences"
      ivt["volume"].should == "91"
      ivt["issue"].should == "11"
    end

    it "should correctly process OJS descriptor 2" do
      path = new_sip_archive 'haskell-nums-pdf.zip'
      s = SipArchive.new path

      s.stub!(:descriptor_doc).and_return(XML::Document.string File.read(File.join(DESCRIPTOR_DIR, "OJStest3.xml")))

      ivt = s.issue_vol_title

      ivt["title"].should == "IEICE Transactions on Fundamentals of Electronics, Communications and Computer Sciences"
      ivt["volume"].should == "88"
      ivt["issue"].should == "3"
    end

    it "should correctly process vol/issue in structMap 1 " do
      path = new_sip_archive 'haskell-nums-pdf.zip'
      s = SipArchive.new path

      s.stub!(:descriptor_doc).and_return(XML::Document.string File.read(File.join(DESCRIPTOR_DIR, "FI04122903.xml")))

      ivt = s.issue_vol_title

      ivt["title"].should == "Everglades Natural History"
      ivt["volume"].should == "1"
      ivt["issue"].should == "3"
    end

    it "should correctly process vol/issue in structMap 2" do
      path = new_sip_archive 'haskell-nums-pdf.zip'
      s = SipArchive.new path

      s.stub!(:descriptor_doc).and_return(XML::Document.string File.read(File.join(DESCRIPTOR_DIR, "WF00000013.xml")))

      ivt = s.issue_vol_title

      ivt["title"].should == "Florida Chautauqua"
      ivt["volume"].should == "1897"
      ivt["issue"].should == nil
    end

    it "should correctly process MARC dmd 1" do
      path = new_sip_archive 'haskell-nums-pdf.zip'
      s = SipArchive.new path

      s.stub!(:descriptor_doc).and_return(XML::Document.string File.read(File.join(DESCRIPTOR_DIR, "MARC_examples_00001.xml")))

      ivt = s.issue_vol_title

      ivt["title"].should == "0 Vol issue test 1 subtitle"
      ivt["volume"].should == "5"
      ivt["issue"].should == nil
    end

    it "should correctly process MARC dmd 2" do
      path = new_sip_archive 'haskell-nums-pdf.zip'
      s = SipArchive.new path

      s.stub!(:descriptor_doc).and_return(XML::Document.string File.read(File.join(DESCRIPTOR_DIR, "MARC_examples2.xml")))

      ivt = s.issue_vol_title

      ivt["title"].should == "0 Vol issue test 1 subtitle"
      ivt["volume"].should == "6"
      ivt["issue"].should == "10"
    end

    it "should correctly process MODS dmd 1" do
      path = new_sip_archive 'haskell-nums-pdf.zip'
      s = SipArchive.new path

      s.stub!(:descriptor_doc).and_return(XML::Document.string File.read(File.join(DESCRIPTOR_DIR, "UF00078627_00013.xml")))

      ivt = s.issue_vol_title

      ivt["title"].should == "Fun. Volume XIII. New Series Volume VI."
      ivt["volume"].should == "n.s. 6"
      ivt["issue"].should == nil
    end

    it "should correctly process MODS dmd 2" do
      path = new_sip_archive 'haskell-nums-pdf.zip'
      s = SipArchive.new path

      s.stub!(:descriptor_doc).and_return(XML::Document.string File.read(File.join(DESCRIPTOR_DIR, "UF00078185_00029.xml")))

      ivt = s.issue_vol_title

      ivt["title"].should == "McTrans newsletter. Vol. 37"
      ivt["volume"].should == "37"
      ivt["issue"].should == nil
    end

    it "should correctly process MODS Enum" do
      path = new_sip_archive 'haskell-nums-pdf.zip'
      s = SipArchive.new path

      s.stub!(:descriptor_doc).and_return(XML::Document.string File.read(File.join(DESCRIPTOR_DIR, "UF00027829_00118.xml")))

      ivt = s.issue_vol_title

      ivt["title"].should == "Florida anthropologist"
      ivt["volume"].should == "2"
      ivt["issue"].should == "8" 
    end

    it "should correctly process DC dmd 1" do
      path = new_sip_archive 'haskell-nums-pdf.zip'
      s = SipArchive.new path

      s.stub!(:descriptor_doc).and_return(XML::Document.string File.read(File.join(DESCRIPTOR_DIR, "2708219.xml")))

      ivt = s.issue_vol_title

      ivt["title"].should == "The Florida Historical Quarterly Volume 84 Issue 4"
      ivt["volume"].should == "84"
      ivt["issue"].should == "4"
    end

    it "should correctly process DC dmd 2" do
      path = new_sip_archive 'haskell-nums-pdf.zip'
      s = SipArchive.new path

      s.stub!(:descriptor_doc).and_return(XML::Document.string File.read(File.join(DESCRIPTOR_DIR, "2646777.xml")))

      ivt = s.issue_vol_title

      ivt["title"].should == "The Florida Historical Quarterly Volume 83 Issue 3"
      ivt["volume"].should == "83"
      ivt["issue"].should == "3"
    end

  end

end
