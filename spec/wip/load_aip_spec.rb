require 'spec_helper'
require 'wip'
require 'wip/ingest'
require 'wip/load_aip'

describe Wip do

  describe "loading from aip" do

    subject do
      ingest_sip 'mimi'
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

    it "should pull in package level provenance" do
      subject.should have_key('old-digiprov')
      events = subject['old-digiprov'].split %r{\n(?=<event)}

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

    it "should pull in datafile level provenance" do
      tif = subject.datafiles.find { |df| df['aip-path'] == '0-normalization.tif'}
      tif.should have_key('old-digiprov')
      events = tif['old-digiprov'].split %r{\n(?=<event)}
      
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

  end

end
