require 'spec_helper'
require 'daitss/archive'

describe Archive do

  describe 'submitting' do

    describe 'a valid package' do

      before :all do
        @archive = Archive.new
        path = new_sip_archive 'mimi.zip'
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

    end

    describe 'invalid package' do

      before :all do
        @archive = Archive.new
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
        @archive = Archive.new
        path = new_sip_archive 'bad-account.zip'
        user = User.get('Bureaucrat')
        @package = @archive.submit path, user

        @package.events.should_not be_empty
        reject_event = @package.events.first :name => 'reject'
        reject_event.should_not be_nil
        reject_event.notes.should include("cannot submit to account BAD-ACT")
      end

      it 'should reject because of the invalid project' do
        @archive = Archive.new
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
