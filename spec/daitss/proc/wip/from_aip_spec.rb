require 'daitss/proc/wip/tarball'
require 'daitss/proc/wip/ingest'
require 'daitss/proc/wip/dmd'
require 'daitss/proc/wip/from_aip'

describe Wip do

  describe 'from an Aip' do

    before :all do
      proto_wip = submit 'wave'
      proto_wip.ingest

      path = proto_wip.path
      id = proto_wip.id
      FileUtils.rm_r path

      @wip = Wip.make path, :disseminate
      @wip.load_from_aip
    end

    it "should load the sip descriptor" do
      @wip.metadata.should have_key( 'sip-descriptor' )
    end

    Wip::DMD_KEYS.each do |key|

      it "should load the (#{key})" do
        @wip.metadata.should have_key( key )
        v = @wip.metadata[key]
        v.should_not be_nil
        v.should_not be_empty
      end

    end

    it "should load the agreement info" do

      ['dmd-account', 'dmd-project'].each do |key|
        @wip.metadata.should have_key( key )
        v = @wip.metadata[key]
        v.should_not be_nil
        v.should_not be_empty
      end

    end

    it "should pull all datafiles" do
      @wip.all_datafiles.should have_exactly(3).items
    end

    it 'should pull the original representation' do
      o_rep = @wip.original_representation
      o_rep.should have_exactly(2).items
      aip_paths = o_rep.map { |f| f['aip-path'] }
      aip_paths.should include(File.join(Wip::SIP_FILES_DIR, 'wave.xml'))
      aip_paths.should include(File.join(Wip::SIP_FILES_DIR, 'obj1.wav'))
    end

    it 'should pull the current representation' do
      c_rep = @wip.current_representation
      c_rep.should have_exactly(2).items
      aip_paths = c_rep.map { |f| f['aip-path'] }
      aip_paths.should include(File.join(Wip::SIP_FILES_DIR, 'wave.xml'))
      aip_paths.should include(File.join(Wip::SIP_FILES_DIR, 'obj1.wav'))
    end

    it 'should pull the normalized representation' do
      n_rep = @wip.normalized_representation
      n_rep.should have_exactly(2).items
      aip_paths = n_rep.map { |f| f['aip-path'] }
      aip_paths.should include(File.join(Wip::SIP_FILES_DIR, 'wave.xml'))
      aip_paths.should include(File.join(Wip::AIP_FILES_DIR, '1-norm-0.wav'))
    end

    describe "package level provenance (events)" do

      before :all do
        @events = @wip['old-digiprov-events'].split %r{\n(?=<event)}
      end

      it 'should have a submission event' do
        submission_event = @events.find do |e|
          doc = XML::Document.string e
          doc.find_first "/P:event[P:eventType = 'submit']", NS_PREFIX
        end

        submission_event.should_not be_nil
      end

      it 'should have a ingest event' do
        ingest_event = @events.find do |e|
          doc = XML::Document.string e
          doc.find_first "/P:event[P:eventType = 'ingest']", NS_PREFIX
        end

        ingest_event.should_not be_nil
      end

    end

    describe "package level provenance (agents)" do

      before :all do
        @agents = @wip['old-digiprov-agents'].split %r{\n(?=<agent)}
      end

      it 'should have a submit agent' do
        submit_agent = @agents.find do |a|
          doc = XML::Document.string a
          doc.find_first "/P:agent[P:agentName = 'DAITSS Account: ACT']", NS_PREFIX
        end

        submit_agent.should_not be_nil
      end

      it 'should have an ingest agent' do
        ingest_agent = @agents.find do |a|
          doc = XML::Document.string a
          doc.find_first "/P:agent[P:agentName = '#{system_agent_spec[:name]}']", NS_PREFIX
        end

        ingest_agent.should_not be_nil
      end

    end

    describe 'datafile level provenance (events)' do

      before :all do
        df = @wip.all_datafiles.find { |df| df['aip-path'] == File.join(Wip::AIP_FILES_DIR, '1-norm-0.wav')}
        @events = df['old-digiprov-events'].split %r{\n(?=<event)}
      end

      it "should have a description event" do

        description_event = @events.find do |e|
          doc = XML::Document.string e
          doc.find_first "/P:event[P:eventType = 'describe']", NS_PREFIX
        end

        description_event.should_not be_nil
      end

      it 'should have a normalization event' do

        normalization_event = @events.find do |e|
          doc = XML::Document.string e
          doc.find_first "/P:event[P:eventType = 'normalize']", NS_PREFIX
        end

        normalization_event.should_not be_nil
      end

    end

    describe "datafile level provenance (agents)" do

      before :all do
        df = @wip.all_datafiles.find { |df| df['aip-path'] == File.join(Wip::AIP_FILES_DIR, '1-norm-0.wav')}
        @agents = df['old-digiprov-agents'].split %r{\n(?=<agent)}
      end

      it 'should have a description agent' do
        describe_agent = @agents.find do |a|
          doc = XML::Document.string a
          doc.find_first "/P:agent[P:agentName = 'Format Description Service']", NS_PREFIX
        end

        describe_agent.should_not be_nil
      end

      it 'should have a normalize agent' do

        normalize_agent = @agents.find do |a|
          doc = XML::Document.string a
          doc.find_first "/P:agent[P:agentName = 'Transformation Service']", NS_PREFIX
        end

        normalize_agent.should_not be_nil
      end

    end

  end

  describe 'multiple datafiles referencing 1 content file' do

    it "should load two datafiles from 1 content file" do
      proto_wip = submit '2content1data'

      proto_sig = proto_wip.all_datafiles.inject({}) do |acc,f|

        acc[f.uri] = {
          :sha => Digest::SHA1.file(f.data_file).hexdigest,
          :path => f['aip-path']
        }

        acc
      end

      proto_wip.ingest

      path = proto_wip.path

      id = proto_wip.id
      uri = proto_wip.uri

      FileUtils.rm_r path

      wip = Wip.make path, :disseminate
      wip.load_from_aip

      sig = wip.all_datafiles.inject({}) do |acc,f|

        acc[f.uri] = {
          :sha => Digest::SHA1.file(f.data_file).hexdigest,
          :path => f['aip-path']
        }

        acc
      end

      proto_sig.should == sig
    end

  end

end
