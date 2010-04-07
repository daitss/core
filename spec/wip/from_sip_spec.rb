require 'spec_helper'
require 'wip/from_sip'

describe Sip do
  subject { Sip.new File.join(SIPS_DIR, 'haskell-nums-pdf') }

  it "should have some files" do
    subject.files.should have_exactly(2).items
    subject.files.should include('Haskell98numbers.pdf', 'haskell-nums-pdf.xml')
  end

  it "should detect the owner id" do
    subject.owner_ids[subject.files[0]].should == 'haskell-numbers-poster'
    subject.owner_ids[subject.files[1]].should be_nil
  end

end

describe Wip do

  describe "transforming from Sip" do

    subject do
      sip = Sip.new File.join(SIPS_DIR, 'haskell-nums-pdf')
      id = UUID.generate :compact
      path = File.join $sandbox, id
      uri = "#{Daitss::CONFIG['uri-prefix']}/#{id}"
      Wip.from_sip path, uri, sip
    end

    it "should have 2 files" do
      subject.original_datafiles.should have_exactly(2).items
    end

    it "should have sip-name in it" do
      subject['sip-name'].should == 'haskell-nums-pdf'
    end

    it "all files should have a sip path" do
      subject.original_datafiles[0]['sip-path'].should == 'Haskell98numbers.pdf'
      subject.original_datafiles[1]['sip-path'].should == 'haskell-nums-pdf.xml'
    end

    it "all files should have a aip path" do
      subject.original_datafiles[0]['aip-path'].should == 'Haskell98numbers.pdf'
      subject.original_datafiles[1]['aip-path'].should == 'haskell-nums-pdf.xml'
    end

    it "should extract FDA account from the descriptor" do
      subject.metadata["dmd-account"].should == "ACT"
    end

    it "should extract FDA project from the descriptor" do
      subject.metadata["dmd-project"].should == "PRJ"
    end

    it "should extract title from the descriptor" do
      subject.metadata["dmd-title"].should == "Haskell Numbers"
    end

    it "should extract issue from the descriptor" do
      subject.metadata["dmd-issue"].should == "2"
    end

    it "should extract volume from the descriptor" do
      subject.metadata["dmd-volume"].should == "1"
    end

    it "should extract entity id from descriptor" do
      subject.metadata["dmd-entity-id"].should == "haskell-nums-pdf"
    end

  end

end
