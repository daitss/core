require 'spec_helper'
require 'wip'
require 'wip/ingest'
require 'wip/dmd'
require 'wip/load_aip'
require 'datafile/normalized_version'

describe Wip do

  describe "loading from aip" do

    subject do
      proto_wip = submit_sip 'mimi'
      proto_wip.ingest!
      id, uri = proto_wip.id, proto_wip.uri
      FileUtils::rm_r proto_wip.path
      wip = blank_wip id, uri
      wip.load_from_aip
      wip
    end

    it "should load the aip descriptor" do
      subject.metadata.should have_key( 'aip-descriptor' )
    end

    it "should load the copy url" do
      subject.metadata.should have_key( 'copy-url' )
    end

    it "should load the copy sha1" do
      subject.metadata.should have_key( 'copy-sha1' )
    end

    it "should load the copy size" do
      subject.metadata.should have_key( 'copy-size' )
    end

    it "should load the dmd" do
       pending 'need integration of submit'

      Wip::DMD_KEYS.each do |key|
        subject.metadata.should have_key( key )
      end

    end

    it "should load the originalName (sip-name)" do
      subject.metadata.should have_key( 'sip-name' )
    end

    it "should pull all datafiles" do
      subject.datafiles.should have_exactly(3).items
    end

    it "should pull representations: original, current, normalized" do

      files = {
        :xml => subject.datafiles.find { |df| df['aip-path'] == 'mimi.xml' },
        :pdf => subject.datafiles.find { |df| df['aip-path'] == 'mimi.pdf' },
        :tif => subject.datafiles.find { |df| df['aip-path'] == '0-normalization.tif'}
      }

      subject.original_rep.should have_exactly(2).items
      subject.original_rep.should include(files[:xml])
      subject.original_rep.should include(files[:pdf])

      subject.current_rep.should have_exactly(2).items
      subject.current_rep.should include(files[:xml])
      subject.current_rep.should include(files[:pdf])

      subject.normalized_rep.should have_exactly(2).items
      subject.normalized_rep.should include(files[:xml])
      subject.normalized_rep.should include(files[:tif])
    end

    it "should pull in package level provenance (events)" do
      subject.should have_key('old-digiprov-events')
      events = subject['old-digiprov-events'].split %r{\n(?=<event)}
      events.should_not be_empty

      # the submission
      submission_event = events.find do |e| 
        doc = XML::Document.string e
        doc.find_first "/P:event[P:eventType = 'submit']", NS_PREFIX
      end

      submission_event.should_not be_nil

      # validation
      validation_event = events.find do |e| 
        doc = XML::Document.string e
        doc.find_first "/P:event[P:eventType = 'comprehensive validation']", NS_PREFIX
      end

      validation_event.should_not be_nil

      # ingest events
      ingest_event = events.find do |e| 
        doc = XML::Document.string e
        doc.find_first "/P:event[P:eventType = 'ingest']", NS_PREFIX
      end

      ingest_event.should_not be_nil
    end

    it "should pull in package level provenance (agents)" do
      subject.should have_key('old-digiprov-agents')
      agents = subject['old-digiprov-agents'].split %r{\n(?=<agent)}
      agents.should_not be_empty

      # submit agent
      submit_agent = agents.find do |a|
        doc = XML::Document.string a
        doc.find_first "/P:agent[P:agentName = 'daitss submission service']", NS_PREFIX
      end

      submit_agent.should_not be_nil

      # validate agent
      validate_agent = agents.find do |a|
        doc = XML::Document.string a
        doc.find_first "/P:agent[P:agentName = 'daitss validation service']", NS_PREFIX
      end

      validate_agent.should_not be_nil

      # ingest agent
      ingest_agent = agents.find do |a|
        doc = XML::Document.string a
        doc.find_first "/P:agent[P:agentName = 'daitss ingest']", NS_PREFIX
      end

      ingest_agent.should_not be_nil
    end

    it "should pull in datafile level provenance (events)" do
      tif = subject.datafiles.find { |df| df['aip-path'] == '0-normalization.tif'}
      tif.should have_key('old-digiprov-events')
      events = tif['old-digiprov-events'].split %r{\n(?=<event)}
      
      # description event
      description_event = events.find do |e| 
        doc = XML::Document.string e
        doc.find_first "/P:event[P:eventType = 'format description']", NS_PREFIX
      end

      description_event.should_not be_nil
      
      # normalization event
      normalization_event = events.find do |e| 
        doc = XML::Document.string e
        doc.find_first "/P:event[P:eventType = 'normalize']", NS_PREFIX
      end

      normalization_event.should_not be_nil
    end

    it "should pull in datafilelevel provenance (agents)" do
      tif = subject.datafiles.find { |df| df['aip-path'] == '0-normalization.tif'}
      tif.should have_key('old-digiprov-agents')
      agents = tif['old-digiprov-agents'].split %r{\n(?=<agent)}

      # description agent
      describe_agent = agents.find do |a|
        doc = XML::Document.string a
        doc.find_first "/P:agent[P:agentName = 'Format Description Service']", NS_PREFIX
      end

      describe_agent.should_not be_nil

      # normalize agent
      normalize_agent = agents.find do |a|
        doc = XML::Document.string a
        doc.find_first "/P:agent[P:agentName = 'daitss transformation service']", NS_PREFIX
      end

      normalize_agent.should_not be_nil
    end

    it "should pull in the normalized_versions of a datafile if exists" do
      xml = subject.datafiles.find { |df| df['aip-path'] == 'mimi.xml' }
      pdf = subject.datafiles.find { |df| df['aip-path'] == 'mimi.pdf' }
      tif = subject.datafiles.find { |df| df['aip-path'] == '0-normalization.tif'}

      xml.normalized_version.should be_nil
      pdf.normalized_version.should == tif
      tif.normalized_version.should be_nil
    end

  end

end
