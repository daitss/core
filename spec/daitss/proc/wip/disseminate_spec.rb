require 'daitss/proc/wip'
require 'daitss/proc/wip/ingest'
require 'daitss/proc/wip/disseminate'
require 'data_mapper'

describe Wip do

  describe "post disseminate" do

    before :all do
      proto_wip = submit 'mimi'
      proto_wip.ingest
      Package.get(proto_wip.id).aip.should_not be_nil

      id = proto_wip.id
      path = proto_wip.path
      FileUtils.rm_r proto_wip.path

      @wip = Wip.make path, :disseminate
      @wip.disseminate
    end

    let(:doc) { XML::Document.string @wip.load_aip_descriptor }

    it "should have an disseminate event" do
      doc.find("//P:event/P:eventType = 'disseminate'", NS_PREFIX).should be_true
    end

    it "should have an disseminate agent" do
      doc.find("//P:agent/P:agentName = '#{system_agent_spec[:name]}'", NS_PREFIX).should be_true
    end

    it "should produce a dip in a disseminate area" do
      @wip.drop_path.should exist_on_fs
    end

    it "should have an IntEntity in the db" do
      ie = Intentity.get(@wip.uri)
      ie.should_not be_nil
      ie.should have(@wip.all_datafiles.size).datafiles
      es = PremisEvent.all :e_type => :disseminate, :relatedObjectId => @wip.uri
      es.should have(1).item
    end

  end

  describe "after multiple disseminations" do

    before :all do

      # ingest it
      proto_wip = submit 'wave'
      proto_wip.ingest
      Package.get(proto_wip.id).aip.should_not be_nil
      @id = proto_wip.id
      path = proto_wip.path
      FileUtils.rm_r proto_wip.path

      # disseminate it twice
      @dips = []

      2.times.each do |n|
        wip = Wip.make path, :disseminate
        wip.disseminate
        @dips << wip.drop_path
        FileUtils.rm_r wip.path
      end

    end

    describe 'the dips' do

      subject { @dips }

      it { should have_exactly(2).items }

      it 'should have an xmlres tarbal for each iteration through processing' do

        subject.each_with_index do |f, ix|
          tarballs = `tar tf #{f}`.split.grep %r{xmlres-\d+.tar}
          tarballs.should have(ix + 2).items
        end

      end

    end

    describe 'aip descriptor' do

      subject do
        aip = Package.get(@id).aip
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
        subject.find("//P:agent/P:agentName = '#{system_agent_spec[:name]}'", NS_PREFIX).should be_true
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

end
