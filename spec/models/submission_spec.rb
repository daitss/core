describe Submission do

  let(:package) do
    a = Account.make :id => 'ACT'
    Project.make :id => DEFAULT_PROJECT_ID, :description => 'default project', :account => a
    proj = Project.make :id => 'PRJ', :account => a
    Package.make :project => proj
  end

  context 'ways to fail extraction' do

    it "should raise error and create sip record if archive cannot be extracted" do
      f = 'scrambled.zip'

      lambda {
        Submission.extract sip_fixture_path(f), :filename => f, :package => package
      }.should raise_error(ExtractionError, /error extracting scrambled.zip/)

    end

    it 'should raise an error if the archive type is unknown' do
      f = 'haskell-nums-pdf.xar'

      lambda {
        Submission.extract sip_fixture_path(f), :filename => f, :package => package
      }.should raise_error(ExtractionError, 'unknown sip extension: .xar')
    end

    it 'should raise an error if the extraction does not result in a directory' do
      f = 'nodir.tar'
      lambda {
        Submission.extract sip_fixture_path(f), :filename => f, :package => package
      }.should raise_error(ExtractionError, 'nodir.tar does not contain a sip')
    end

  end

  context 'good zips and tars' do

    it "should create sip from zip file" do
      f = 'haskell-nums-pdf.zip'
      s = Submission.extract sip_fixture_path(f), :filename => f, :package => package
      s.should be_a(Submission)
    end

    it "should create sip from tar file" do
      f = 'haskell-nums-pdf.tar'
      s = Submission.extract sip_fixture_path(f), :filename => f, :package => package
      s.should be_a(Submission)
    end

  end

  context 'ways to fail validation' do

    context 'the package name' do

      it "should not have a very long name" do
        f = 'name-too-long-xxxxxxxxxxxxxxxxxxx.zip'
        s = Submission.extract sip_fixture_path(f), :filename => f, :package => package
        s.should_not be_valid
        s.errors[:name].should include('is too long (33) max is 32')
      end

    end

    context 'the descriptor' do


      it "should exist" do
        f = 'missing-descriptor.zip'
        s = Submission.extract sip_fixture_path(f), :filename => f, :package => package
        s.should_not be_valid
        s.errors[:descriptor].should include('missing descriptor')
      end

      it "should be valid" do
        f = 'invalid-descriptor.zip'
        s = Submission.extract sip_fixture_path(f), :filename => f, :package => package
        s.should_not be_valid
        s.errors[:descriptor].should include(%q{invalid-descriptor.xml 48: cvc-id.1: There is no ID/IDREF binding for IDREF 'FILE-0'.})
      end

      it "should have one agreement" do
        f = 'missing-agreement.zip'
        s = Submission.extract sip_fixture_path(f), :filename => f, :package => package
        s.should_not be_valid
        s.errors[:descriptor].should include("missing agreement info")
      end

      it "should no more than one agreement" do
        f = 'multiple-agreements.zip'
        s = Submission.extract sip_fixture_path(f), :filename => f, :package => package
        s.should_not be_valid
        s.errors[:descriptor].should include("multiple agreement info")
      end

    end

    context 'the contents' do

      it "should not have special characters" do
        f = 'special-characters.zip'
        s = Submission.extract sip_fixture_path(f), :filename => f, :package => package
        s.should_not be_valid
        s.errors[:content].should include(%q{invalid characters in file name: 00039'.txt})
      end

      it "should not have special characters in a low level file" do
        f = 'lower-level-special-characters.zip'
        s = Submission.extract sip_fixture_path(f), :filename => f, :package => package
        s.should_not be_valid
        s.errors[:content].should include(%q{invalid characters in file name: Content/UF00001074'.pdf})
      end

      it "should not have hidden files" do
        f = 'described-hidden-file.zip'
        s = Submission.extract sip_fixture_path(f), :filename => f, :package => package
        s.should_not be_valid
        s.errors[:content].should include('invalid characters in file name: .hidden.txt')
      end

      it "should have good checksums for files" do
        f = 'checksum-mismatch.zip'
        s = Submission.extract sip_fixture_path(f), :filename => f, :package => package
        s.should_not be_valid
        s.errors[:content].should include("wrong md5: ateam.tiff; expected: 905ae75bc4595521e350564c90a56d28; actual: 805ae75bc4595521e350564c90a56d28")
      end

      it "should contain all described files" do
        f = 'missing-content-file.zip'
        s = Submission.extract sip_fixture_path(f), :filename => f, :package => package
        s.should_not be_valid
        s.errors[:content].should include("missing content file: ateam.tiff")
      end

    end

  end

  describe 'descriptive metadata' do

    let :submission do
      f = 'haskell-nums-pdf.zip'
      Submission.extract sip_fixture_path(f), :filename => f, :package => package
    end

    specify { submission.descriptor_doc.to_s.should_not be_nil }
    specify { submission.project.account.id.should == 'ACT' }
    specify { submission.project.id.should == 'PRJ' }
    specify { submission.title.should == 'Haskell Numbers' }
    specify { submission.volume.should == '1' }
    specify { submission.issue.should == '2' }
    specify { submission.entity_id.should == 'haskell-nums-pdf' }

    it "should correctly process OJS descriptor 1" do
      f = file_fixture_path 'OJStest6.xml'
      data = File.read f
      doc = LibXML::XML::Document.string data
      submission.stub!(:descriptor_doc).and_return(doc)

      submission.title.should == "IEICE Transactions on Fundamentals of Electronics, Communications and Computer Sciences"
      submission.volume.should == "91"
      submission.issue.should == "11"
    end

    it "should correctly process OJS descriptor 2" do
      f = file_fixture_path 'OJStest3.xml'
      data = File.read f
      doc = LibXML::XML::Document.string data
      submission.stub!(:descriptor_doc).and_return(doc)

      submission.title.should == "IEICE Transactions on Fundamentals of Electronics, Communications and Computer Sciences"
      submission.volume.should == "88"
      submission.issue.should == "3"
    end

    it "should correctly process vol/issue in structMap 1 " do
      f = file_fixture_path 'FI04122903.xml'
      data = File.read f
      doc = LibXML::XML::Document.string data
      submission.stub!(:descriptor_doc).and_return(doc)

      submission.title.should == "Everglades Natural History"
      submission.volume.should == "1"
      submission.issue.should == "3"
    end


    it "should correctly process vol/issue in structMap 2" do
      f = file_fixture_path 'WF00000013.xml'
      data = File.read f
      doc = LibXML::XML::Document.string data
      submission.stub!(:descriptor_doc).and_return(doc)

      submission.title.should == "Florida Chautauqua"
      submission.volume.should == "1897"
      submission.issue.should == nil
    end

    it "should correctly process MARC dmd 1" do
      f = file_fixture_path 'MARC_examples_00001.xml'
      data = File.read f
      doc = LibXML::XML::Document.string data
      submission.stub!(:descriptor_doc).and_return(doc)

      submission.title.should == "0 Vol issue test 1 subtitle"
      submission.volume.should == "5"
      submission.issue.should == nil
    end

    it "should correctly process MARC dmd 2" do
      f = file_fixture_path 'MARC_examples2.xml'
      data = File.read f
      doc = LibXML::XML::Document.string data
      submission.stub!(:descriptor_doc).and_return(doc)

      submission.title.should == "0 Vol issue test 1 subtitle"
      submission.volume.should == "6"
      submission.issue.should == "10"
    end

    it "should correctly process MODS dmd 1" do
      f = file_fixture_path 'UF00078627_00013.xml'
      data = File.read f
      doc = LibXML::XML::Document.string data
      submission.stub!(:descriptor_doc).and_return(doc)

      submission.title.should == "Fun. Volume XIII. New Series Volume VI."
      submission.volume.should == "n.s. 6"
      submission.issue.should == nil
    end

    it "should correctly process MODS dmd 2" do
      f = file_fixture_path 'UF00078185_00029.xml'
      data = File.read f
      doc = LibXML::XML::Document.string data
      submission.stub!(:descriptor_doc).and_return(doc)

      submission.title.should == "McTrans newsletter. Vol. 37"
      submission.volume.should == "37"
      submission.issue.should == nil
    end

    it "should correctly process MODS Enum" do
      f = file_fixture_path 'UF00027829_00118.xml'
      data = File.read f
      doc = LibXML::XML::Document.string data
      submission.stub!(:descriptor_doc).and_return(doc)

      submission.title.should == "Florida anthropologist"
      submission.volume.should == "2"
      submission.issue.should == "8"
    end

    it "should correctly process DC dmd 1" do
      f = file_fixture_path '2708219.xml'
      data = File.read f
      doc = LibXML::XML::Document.string data
      submission.stub!(:descriptor_doc).and_return(doc)

      submission.title.should == "The Florida Historical Quarterly Volume 84 Issue 4"
      submission.volume.should == "84"
      submission.issue.should == "4"
    end

    it "should correctly process DC dmd 2" do
      f = file_fixture_path '2646777.xml'
      data = File.read f
      doc = LibXML::XML::Document.string data
      submission.stub!(:descriptor_doc).and_return(doc)

      submission.title.should == "The Florida Historical Quarterly Volume 83 Issue 3"
      submission.volume.should == "83"
      submission.issue.should == "3"
    end

  end

end
