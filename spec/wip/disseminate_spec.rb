require 'spec_helper'
require 'wip'
require 'wip/disseminate'
require 'datamapper'

describe Wip do

  describe "that cannot disseminate" do

    it "should fail if an aip does not exist for the wip" do
      wip = submit_sip 'mimi'
      lambda { wip.disseminate }.should raise_error(DataMapper::ObjectNotFoundError)
    end

    it "should snafu if there is anything wrong with dissemination" do
      wip = ingest_sip 'mimi'
      real_description_url = CONFIG['description-url']
      CONFIG['description-url'] = "#{STATUS_ECHO_URL}/500/foo"
      wip.disseminate
      wip.should be_snafu
      CONFIG['description-url'] = real_description_url
    end

    describe "that can disseminate" do

      subject do 
        wip = ingest_sip 'mimi'
        wip.disseminate
        wip
      end

      it "should update the aip it came from" do
         aip = Aip.get subject.id 
         aip.should_not be_nil
         doc = XML::Document.string aip.xml
         disseminate_event = doc.find_first "P:event[P:eventType = 'disseminate']"
         disseminate_event.should_not be_nil
      end

      it "should produce a dip in a disseminate area" do
          path = File.join CONFIG['disseminate-dir-path'], "#{subject.id}.tar"
          File.exist?(path).should be_true
      end

    end

  end

end
