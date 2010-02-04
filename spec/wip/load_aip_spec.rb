require 'spec_helper'
require 'wip'
require 'wip/ingest'
require 'wip/load_aip'

describe Wip do

  describe "loading from aip" do

    subject do
      original_wip = submit_sip 'mimi'
      original_wip.ingest!

      aip = Aip.get original_wip.id
      aip.should_not be_nil
      FileUtils.rm_r original_wip.path

      path = File.join $sandbox, aip.id 
      wip = Wip.new path, aip.uri
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
      tif = subject.datafiles.find { |df| df['aip-path'] == '0-normalization.tif'}
    end

  end

end
