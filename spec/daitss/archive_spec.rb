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

end
