require 'spec_helper'
require 'daitss/proc/wip/from_sip'

describe Wip do

  describe "from a Sip" do

    subject do
      sa = SipArchive.new new_sip_archive('haskell-nums-pdf.zip')
      ws = new_workspace

      id = Package.new.id
      uri = "#{Daitss::CONFIG['uri-prefix']}/#{id}"

      Wip.from_sip_archive ws, id, uri, sa
    end

    it "should have sip descriptor as metadata" do
      sd_df = subject.original_datafiles.find { |df| df['sip-path'] == "#{subject['sip-name']}.xml" }
      subject['sip-descriptor'].should == sd_df.open.read
    end

    it "should have 2 files" do
      subject.original_datafiles.should have_exactly(2).items
    end

    it "should have sip-name in it" do
      subject['sip-name'].should == 'haskell-nums-pdf'
    end

    it "all files should have a sip path" do
      subject.original_datafiles[0]['sip-path'].should == 'haskell-nums-pdf.xml'
      subject.original_datafiles[1]['sip-path'].should == 'Haskell98numbers.pdf'
    end

    it "all files should have a aip path" do
      subject.original_datafiles[0]['aip-path'].should == File.join(AipArchive::SIP_FILES_DIR, 'haskell-nums-pdf.xml')
      subject.original_datafiles[1]['aip-path'].should == File.join(AipArchive::SIP_FILES_DIR, 'Haskell98numbers.pdf')
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
