require 'spec_helper'
require 'daitss/archive'

describe Daitss::Archive do

  describe 'when submitting' do

    describe 'a valid package' do

      before :all do
        @archive = Daitss.archive
        path = new_sip_archive 'haskell-nums-pdf.zip'
        user = User.get('Bureaucrat')
        @package = @archive.submit path, user
      end

      it 'should submit' do
        @package.events.should_not be_empty
        reject_event = @package.events.first :name => 'submit'
        reject_event.should_not be_nil
      end

      it 'should create an ingest wip' do
        wip = @archive.workspace[@package.id]
        wip.should_not be_nil
        wip.task.should == :ingest
      end

      describe 'the resulting sip' do
        subject { @package.sip }

        it 'should have the size in bytes' do
          subject.size_in_bytes.should == 29508
        end

        it 'should have the number of data files' do
          subject.number_of_datafiles.should == 2
        end

      end

      describe 'the resulting wip' do

        subject { Daitss.archive.workspace[@package.id] }

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

    describe 'invalid package' do

      before :all do
        @archive = Daitss.archive
        path = new_sip_archive 'missing-descriptor.zip'
        user = User.get('Bureaucrat')
        @package = @archive.submit path, user
      end

      it 'should reject' do
        @package.events.should_not be_empty
        reject_event = @package.events.first :name => 'reject'
        reject_event.should_not be_nil
      end

      it 'should not create an ingest wip' do
        wip = @archive.workspace[@package.id]
        wip.should be_nil
      end

    end

    describe 'submitting a with bad agreement info' do

      it 'should reject because of the invalid account' do
        @archive = Daitss.archive
        path = new_sip_archive 'bad-account.zip'
        user = User.get('Bureaucrat')
        @package = @archive.submit path, user

        @package.events.should_not be_empty
        reject_event = @package.events.first :name => 'reject'
        reject_event.should_not be_nil
        reject_event.notes.should include("cannot submit to account BAD-ACT")
      end

      it 'should reject because of the invalid project' do
        @archive = Daitss.archive
        path = new_sip_archive 'bad-project.zip'
        user = User.get('Bureaucrat')
        @package = @archive.submit path, user

        @package.events.should_not be_empty
        reject_event = @package.events.first :name => 'reject'
        reject_event.should_not be_nil
        reject_event.notes.should include("no project BAD-PRJ for account ACT")
      end

    end

  end

end
