require 'spec_helper'
require 'wip/ingest'
require 'wip/dmd'
require 'wip/from_aip'

describe Wip do

  describe 'from an Aip' do

    before :all do
      proto_wip = submit 'wave'
      proto_wip.ingest!
      path = proto_wip.path
      FileUtils.rm_r path
      @wip = Wip.from_aip path
    end

    it "should load the aip descriptor" do
      @wip.metadata.should have_key( 'aip-descriptor' )
    end

    it "should load the sip descriptor" do
      @wip.metadata.should have_key( 'sip-descriptor' )
    end

    it "should load the copy url" do
      @wip.metadata.should have_key( 'copy-url' )
    end

    it "should load the copy sha1" do
      @wip.metadata.should have_key( 'copy-sha1' )
    end

    it "should load the copy size" do
      @wip.metadata.should have_key( 'copy-size' )
    end

    it "should load the account" do
      @wip.metadata.should have_key( 'dmd-account' )
    end

    it "should load the project" do
      @wip.metadata.should have_key( 'dmd-project' )
    end

    Wip::DMD_KEYS.each do |key|

      it "should load the (#{key})" do
        @wip.metadata.should have_key( key )
      end

    end

    it "should load the originalName (sip-name)" do
      @wip.metadata.should have_key( 'sip-name' )
    end

    it "should pull all datafiles" do
      @wip.all_datafiles.should have_exactly(3).items
    end

    it 'should pull the original representation' do
      o_rep = @wip.original_representation
      o_rep.should have_exactly(2).items
      o_rep[1]['aip-path'].should == 'wave.xml'
      o_rep[0]['aip-path'].should == 'obj1.wav'
    end

    it 'should pull the current representation' do
      c_rep = @wip.current_representation
      c_rep.should have_exactly(2).items
      c_rep[1]['aip-path'].should == 'wave.xml'
      c_rep[0]['aip-path'].should == 'obj1.wav'
    end

    it 'should pull the normalized representation' do
      n_rep = @wip.normalized_representation
      n_rep.should have_exactly(2).items
      n_rep[1]['aip-path'].should == 'wave.xml'
      n_rep[0]['aip-path'].should == '0-norm-0.wav'
    end

    describe "package level provenance (events)" do

      before :all do
        @events = @wip['old-digiprov-events'].split %r{\n(?=<event)}
      end

      it 'should have a submission event' do
        submission_event = @events.find do |e|
          doc = XML::Document.string e
          doc.find_first "/P:event[P:eventType = 'submit']", NS_PREFIX
        end

        submission_event.should_not be_nil
      end

      it 'should have a ingest event' do
        ingest_event = @events.find do |e|
          doc = XML::Document.string e
          doc.find_first "/P:event[P:eventType = 'ingest']", NS_PREFIX
        end

        ingest_event.should_not be_nil
      end

    end

    describe "package level provenance (agents)" do

      before :all do
        @agents = @wip['old-digiprov-agents'].split %r{\n(?=<agent)}
      end

      it 'should have a submit agent' do
        submit_agent = @agents.find do |a|
          doc = XML::Document.string a
          doc.find_first "/P:agent[P:agentName = 'daitss submission service']", NS_PREFIX
        end

        submit_agent.should_not be_nil
      end

      it 'should have an ingest agent' do
        ingest_agent = @agents.find do |a|
          doc = XML::Document.string a
          doc.find_first "/P:agent[P:agentName = 'daitss ingest']", NS_PREFIX
        end

        ingest_agent.should_not be_nil
      end

    end

    describe 'datafile level provenance (events)' do

      before :all do
        df = @wip.all_datafiles.find { |df| df['aip-path'] == '0-norm-0.wav'}
        @events = df['old-digiprov-events'].split %r{\n(?=<event)}
      end

      it "should have a description event" do

        description_event = @events.find do |e|
          doc = XML::Document.string e
          doc.find_first "/P:event[P:eventType = 'format description']", NS_PREFIX
        end

        description_event.should_not be_nil
      end

      it 'should have a normalization event' do

        normalization_event = @events.find do |e|
          doc = XML::Document.string e
          doc.find_first "/P:event[P:eventType = 'normalize']", NS_PREFIX
        end

        normalization_event.should_not be_nil
      end

    end

    describe "datafile level provenance (agents)" do

      before :all do
        df = @wip.all_datafiles.find { |df| df['aip-path'] == '0-norm-0.wav'}
        @agents = df['old-digiprov-agents'].split %r{\n(?=<agent)}
      end

      it 'should have a description agent' do
        describe_agent = @agents.find do |a|
          doc = XML::Document.string a
          doc.find_first "/P:agent[P:agentName = 'Format Description Service']", NS_PREFIX
        end

        describe_agent.should_not be_nil
      end

      it 'should have a normalize agent' do
        normalize_agent = @agents.find do |a|
          doc = XML::Document.string a
          doc.find_first "/P:agent[P:agentName = 'daitss transformation service']", NS_PREFIX
        end

        normalize_agent.should_not be_nil
      end

    end

  end

end
