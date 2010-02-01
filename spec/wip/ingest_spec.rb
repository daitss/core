require 'wip'
require 'db/aip'
require 'ingest'
require 'spec_helper'

describe Wip do

  it "should reject one that fails validation"
  it "should snafu one that has trouble ingesting"

  describe "that is ingested" do

    before :all do
      @wip = submit_sip 'mimi'
      @wip.ingest!
    end

    it "should be validated" do
      @wip.tags.should have_key('validate')
    end

    it "should have an aip descriptor" do
      @wip.tags.should have_key('make-aip-descriptor')
    end

    it "should have made an aip" do
      Aip.get(@wip.id).should_not be_nil
    end

  end

end
