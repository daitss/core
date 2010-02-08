require 'spec_helper'
require 'wip/preserve'
require 'wip/representation'

describe Wip do

  describe "with one migration" do
    before :all do
      @wip = submit_sip 'mimi' 
      @wip.preserve!

      @files = {
        :xml => @wip.datafiles.find { |df| df['sip-path'] == 'mimi.xml' },
        :pdf => @wip.datafiles.find { |df| df['sip-path'] == 'mimi.pdf' },
        :tif => @wip.datafiles.find { |df| df['aip-path'] }
      }
    end

    it "should have 3 datafiles" do
      @wip.datafiles.should have_exactly(3).items
      describe_tags = @wip.tags.keys.select { |key| key =~ /describe-\d+/ }
      describe_tags.should have_exactly(3).items
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

      migration_tags = @wip.tags.keys.select { |key| key =~ /migrate-\d+/ }
      migration_tags.should have_exactly(2).items
    end

    it "should have a normalized representation just with only an xml and a tif" do
      @wip.normalized_rep.should have_exactly(2).items
      @wip.normalized_rep.should include(@files[:xml])
      @wip.normalized_rep.should include(@files[:tif])
      @wip.normalized_rep.should_not include(@files[:pdf])

      normalization_tags = @wip.tags.keys.select { |key| key =~ /normalize-\d+/ }
      normalization_tags.should have_exactly(2).items
    end

  end

end
