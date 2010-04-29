require 'spec_helper'
require 'wip'
require 'wip/ingest'
require 'wip/disseminate'
require 'datamapper'

describe Wip do

  describe "that cannot disseminate" do

    it "should raise error if an aip does not exist for the wip" do
      wip = submit 'mimi'
      lambda { wip.disseminate }.should raise_error(DataMapper::ObjectNotFoundError)
    end

    it "should raise error if there is anything wrong with dissemination" do
      proto_wip = submit 'mimi'
      proto_wip.ingest!
      id, uri = proto_wip.id, proto_wip.uri
      FileUtils::rm_r proto_wip.path
      wip = blank_wip id, uri

      override_service 'description-url', 500 do
        lambda { wip.disseminate }.should raise_error(Net::HTTPFatalError)
      end

    end

  end

  describe "post disseminate" do

    subject do
      proto_wip = submit 'mimi'
      proto_wip.ingest!
      Aip.get! proto_wip.id
      id, uri = proto_wip.id, proto_wip.uri
      FileUtils::rm_r proto_wip.path
      wip = blank_wip id, uri
      wip.tags['drop-path'] = "/tmp/#{id}.tar"
      wip.disseminate
      wip
    end

    it "should have an disseminate event" do
      doc = XML::Document.string subject['aip-descriptor']
      doc.find("//P:event/P:eventType = 'disseminate'", NS_PREFIX).should be_true
    end

    it "should have an disseminate agent" do
      doc = XML::Document.string subject['aip-descriptor']
      doc.find("//P:agent/P:agentName = 'daitss disseminate'", NS_PREFIX).should be_true
    end

    it "should produce a dip in a disseminate area" do
      path = subject.tags['drop-path']
      File.exist?(path).should be_true
    end

  end

  describe "after multiple disseminations" do

    before :all do

      # ingest it
      proto_wip = submit 'wave'
      proto_wip.ingest!
      Aip.get! proto_wip.id
      @id, @uri = proto_wip.id, proto_wip.uri
      FileUtils::rm_r proto_wip.path

      # disseminate it twice
      2.times.each do |n|
        wip = blank_wip @id, @uri
        wip.tags['drop-path'] = "/tmp/#{@id}-#{n}.tar"
        wip.disseminate
        FileUtils::rm_r wip.path
      end

    end

    subject do
      aip = Aip.get! @id
      XML::Document.string aip.xml
    end

    it 'should have two dissemination events' do
      subject.find("count(//P:event[P:eventType = 'disseminate'])", NS_PREFIX).should == 2
    end

    it "should not collide identifiers" do
      events = subject.find("//P:event[P:eventType = 'disseminate']/P:eventIdentifier/P:eventIdentifierValue", NS_PREFIX)
      a = events[0].content
      b = events[1].content
      a.should_not == b
    end

    it "should have one dissemination agent" do
      subject.find("//P:agent/P:agentName = 'daitss disseminate'", NS_PREFIX).should be_true
    end

    describe 'obsolete files' do

      before :all do
        @ofs = subject.find("//M:file[not(M:FLocat)]", NS_PREFIX)
      end

      it "should have 2 obsolete files" do
        @ofs.should have_exactly(2).items
      end

      it "should have 1 PREMIS object for all obsolete files" do

        @ofs.each do |df|
          subject.find(%Q{
            //P:object [
              P:objectIdentifier/P:objectIdentifierValue = '#{ df['OWNERID'] }'
            ]
          }, NS_PREFIX).should have_exactly(1).items

        end

      end

      it "should have 1 obsolete event for every obsolete file" do

        @ofs.each do |df|
          subject.find(%Q{
            //P:event [P:eventType = 'obsolete']
                      [P:linkingObjectIdentifier /
                         P:linkingObjectIdentifierValue = '#{ df['OWNERID'] }'
                      ]
          }, NS_PREFIX).should have_exactly(1).items

        end

      end

      it "should have 1 obsolete agent for every obsolete file" do

        @ofs.each do |df|
          agent_id = subject.find_first(%Q{
            //P:event [P:eventType = 'obsolete']
                      [P:linkingObjectIdentifier / P:linkingObjectIdentifierValue = '#{ df['OWNERID'] }' ]
                        / P:linkingAgentIdentifier / P:linkingAgentIdentifierValue
          }, NS_PREFIX).content

          subject.find(%Q{
            //P:agent/P:agentIdentifier/P:agentIdentifierValue = '#{agent_id}'
          }, NS_PREFIX).should be_true

        end

      end

    end

  end

end
