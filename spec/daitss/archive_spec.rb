require 'spec_helper'
require 'daitss/archive'

describe Archive do

  describe 'submitting a valid package' do

    before :all do
      @archive = Archive.new
      path = new_sip_archive 'mimi.zip'
      user = Program.first :identifier => 'Bureaucrat'
      @sip = @archive.submit path, user
    end

    it 'should submit' do
      @sip.operations_events.should_not be_empty
      reject_event = @sip.operations_events.find { |e| e.event_name == 'submit' }
      reject_event.should_not be_nil
    end

    it 'should create an ingest wip' do
      wip = @archive.workspace[@sip.id]
      wip.should_not be_nil
      wip.task.should == :ingest
    end

  end

  describe 'submitting an invalid package' do

    before :all do
      @archive = Archive.new
      path = new_sip_archive 'missing-descriptor.zip'
      user = Program.first :identifier => 'Bureaucrat'
      @sip = @archive.submit path, user
    end

    it 'should reject' do
      @sip.operations_events.should_not be_empty
      reject_event = @sip.operations_events.find { |e| e.event_name == 'reject' }
      reject_event.should_not be_nil
    end

    it 'should not create an ingest wip' do
      wip = @archive.workspace[@sip.id]
      wip.should be_nil
    end

  end

  describe 'submitting a with bad agreement info' do

    it 'should reject because of the invalid account' do
      @archive = Archive.new
      path = new_sip_archive 'bad-account.zip'
      user = Program.first :identifier => 'Bureaucrat'
      @sip = @archive.submit path, user

      @sip.operations_events.should_not be_empty
      reject_event = @sip.operations_events.find { |e| e.event_name == 'reject' }
      reject_event.should_not be_nil
      reject_event.notes.should include("cannot submit to account BAD-ACT")
    end

    it 'should reject because of the invalid project' do
      @archive = Archive.new
      path = new_sip_archive 'bad-project.zip'
      user = Program.first :identifier => 'Bureaucrat'
      @sip = @archive.submit path, user

      @sip.operations_events.should_not be_empty
      reject_event = @sip.operations_events.find { |e| e.event_name == 'reject' }
      reject_event.should_not be_nil
      reject_event.notes.should include("cannot submit to project BAD-PRJ")
    end

  end

end
