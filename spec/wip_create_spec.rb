require 'spec_helper'
require 'wip/create'

describe Sip do
end

describe "Sip -> Wip" do

  subject do
    sip = Sip.new File.join(SIP_DIR, 'haskell-nums-pdf')
    Wip.make_from_sip File.join($sandbox, UG.generate), URI_PREFIX, sip
  end

  it "should have 2 files" do
    subject.datafiles.should have_exactly(2).items
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
