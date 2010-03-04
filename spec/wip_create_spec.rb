require 'spec_helper'
require 'wip/create'

describe Sip do
  subject { Sip.new File.join(SIP_DIR, 'haskell-nums-pdf') }

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
    sip = Sip.new File.join(SIP_DIR, 'haskell-nums-pdf')
    Wip.make_from_sip File.join($sandbox, UG.generate), URI_PREFIX, sip
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
