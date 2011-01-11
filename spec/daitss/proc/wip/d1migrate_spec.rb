require 'daitss/proc/wip'
require 'daitss/proc/wip/ingest'
require 'daitss/proc/wip/disseminate'
require 'data_mapper'

describe Wip do

  describe "that cannot disseminate" do

    it "should raise error if no d1 aip exists" do
      # wip = submit 'mimi'
      # lambda { wip.disseminate! }.should raise_error("no aip for #{wip.id}")
    end

  end

  describe "post d1migrate" do

    before :all do
      # TODO setup a d1 aip in storage
      # TODO setup the stubs in the db
      # TODO make a blank wip with task d1migrate
      #@wip.d1migrate!
    end

    it "should have an d1migrate event" do
      pending 'waiting on other stuff'
      doc = XML::Document.string @wip['aip-descriptor']
      doc.find("//P:event/P:eventType = 'd1migrate'", NS_PREFIX).should be_true
    end

    it "should have an d1migrate agent" do
      pending 'waiting on other stuff'
      doc = XML::Document.string @wip['aip-descriptor']
      doc.find("//P:agent/P:agentName = '#{system_agent_spec[:name]}'", NS_PREFIX).should be_true
    end

    it "should have an IntEntity in the db" do
      pending 'waiting on other stuff'
      ie = Intentity.get(@wip.uri)
      ie.should_not be_nil
      ie.should have(@wip.all_datafiles.size).datafiles
      es = PremisEvent.all :e_type => :d1_migrate, :relatedObjectId => @wip.uri
      es.should have(1).item
    end

  end

end
