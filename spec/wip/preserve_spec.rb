require 'spec_helper'
require 'wip/preserve'
require 'wip/representation'

shared_examples_for "all preservations" do

  it "should have every datafile described" do

    @wip.datafiles.each do |df|
      @wip.tags.should have_key("step.describe-#{df.id}")
      df.should have_key('describe-file-object')
      df.should have_key('describe-event')
      df.should have_key('describe-agent')
    end

  end

end

describe Wip do

  describe "with no normalization" do
    it_should_behave_like "all preservations"

    before :all do
      @wip = submit 'lorem' 
      @wip.preserve!

      @files = {
        :xml => @wip.datafiles.find { |df| df['sip-path'] == 'lorem.xml' },
        :txt => @wip.datafiles.find { |df| df['sip-path'] == 'lorem_ipsum.txt' },
      }

    end

    it "should not have a normalized representation" do
      @wip.normalized_rep.should be_empty
    end

  end

  describe "with one normalization" do
    it_should_behave_like "all preservations"

    before :all do
      @wip = submit 'mimi' 
      @wip.preserve!

      @files = {
        :xml => @wip.datafiles.find { |df| df['sip-path'] == 'mimi.xml' },
        :pdf => @wip.datafiles.find { |df| df['sip-path'] == 'mimi.pdf' },
        :tif => @wip.datafiles.find { |df| df['aip-path'] }
      }

    end

    it "should have an original representation with only an xml and a pdf" do
      @wip.original_rep.should have_exactly(2).items
      @wip.original_rep.should include(@files[:xml])
      @wip.original_rep.should include(@files[:pdf])
      @wip.original_rep.should_not include(@files[:tif])
    end

    it "should have a current representation just with only an xml and a pdf" do
      @wip.current_rep.should have_exactly(2).items
      @wip.current_rep.should include(@files[:xml])
      @wip.current_rep.should include(@files[:pdf])
      @wip.current_rep.should_not include(@files[:tif])
    end

    it "should have a normalized representation just with only an xml and a tif" do
      @wip.normalized_rep.should have_exactly(2).items
      @wip.normalized_rep.should include(@files[:xml])
      @wip.normalized_rep.should include(@files[:tif])
      @wip.normalized_rep.should_not include(@files[:pdf])
    end

  end

end
