require 'spec_helper'
require 'wip/create'

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

describe "Sip -> Wip" do

  subject do
    sip = Sip.new File.join(SIPS_DIR, 'haskell-nums-pdf')
    Wip.make_from_sip File.join($sandbox, UUID.generate), Daitss::CONFIG['uri-prefix'], sip
  end

  it "should have 2 files" do
    subject.datafiles.should have_exactly(2).items
  end

  it "should have sip-name in it" do
      subject['sip-name'].should == 'haskell-nums-pdf'
  end

  it "all files should have a sip path" do
    subject.datafiles[0]['sip-path'].should == 'Haskell98numbers.pdf'
    subject.datafiles[1]['sip-path'].should == 'haskell-nums-pdf.xml'
  end

  it "should have owner-id where applicable" do
    subject.datafiles[0]['owner-id'].should == 'haskell-numbers-poster'
    subject.datafiles[1]['owner-id'].should be_nil
  end

end

describe "SIP DMD Extraction" do
  subject do
    sip = Sip.new File.join(SIPS_DIR, 'ateam-dmd')
    Wip.make_from_sip File.join($sandbox, UUID.generate), Daitss::CONFIG['uri-prefix'], sip
  end

  it "should extract FDA account from the descriptor" do
    subject.metadata["dmd-account"].should == "ACT"
  end

  it "should extract FDA project from the descriptor" do
    subject.metadata["dmd-project"].should == "PRJ"
  end

  it "should extract title from the descriptor" do
    subject.metadata["dmd-title"].should == "The (fd)A Team"
  end

  it "should extract issue from the descriptor" do
    subject.metadata["dmd-issue"].should == "2"
  end

  it "should extract volume from the descriptor" do
    subject.metadata["dmd-volume"].should == "1"
  end

  it "should extract entity id from descriptor" do
    subject.metadata["dmd-entity-id"].should == "ateam-dmd"
  end
end

describe "SIP DMD Extraction when no DMD present" do
  subject do
    sip = Sip.new File.join(SIPS_DIR, 'ateam-nodmd')
    Wip.make_from_sip File.join($sandbox, UUID.generate), Daitss::CONFIG['uri-prefix'], sip
  end

  it "account should be empty if not present in descriptor" do
    subject.metadata["dmd-account"].should == ""
  end

  it "project should be empty of not present in descriptor" do
    subject.metadata["dmd-project"].should == ""
  end

  it "title should be empty if not present in descriptor" do
    subject.metadata["dmd-title"].should == ""
  end

  it "issue should be empty if not present in descriptor" do
    subject.metadata["dmd-issue"].should == ""
  end

  it "volume should be empty if not present in descriptor" do
    subject.metadata["dmd-volume"].should == ""
  end

  it "entity id should be empty if not present in descriptor" do
    subject.metadata["dmd-entity-id"].should == ""
  end
end
