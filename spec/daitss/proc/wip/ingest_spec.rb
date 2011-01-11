require 'daitss/proc/wip'
require 'daitss/model/aip'
require 'daitss/proc/wip/ingest'

require 'daitss/db/int_entity'

describe 'Wip' do

  let(:wip) do
    w = submit 'mimi'
    w.ingest
    w
  end

  let(:intentity) { wip.package.intentity }

  it "should have an IntEntity in the db" do
    intentity.should_not be_nil
    intentity.should have(wip.all_datafiles.size).datafiles
  end

  let(:aip) { wip.package.aip }

  it "should have made an aip" do
    aip.should_not be_nil
  end

  context "the descriptor" do

    let(:descriptor) { XML::Document.string wip.load_aip_descriptor }

    context "ingest digiprov" do

      it "should have an ingest event" do
        descriptor.find("//P:event/P:eventType = 'ingest'", NS_PREFIX).should be_true
      end

      it "should have an ingest agent" do
        descriptor.find("//P:agent/P:agentName = '#{system_agent_spec[:name]}'", NS_PREFIX).should be_true
      end

      it "should have a sip descriptor denoted" do
        descriptor.find("//M:file/@USE='sip descriptor'", NS_PREFIX).should be_true
      end

    end

    context "virus check digiprov" do

      it 'should return a premis event' do
        descriptor.find("//P:event/P:eventType = 'virus check'", NS_PREFIX).should be_true
      end

      it 'should return a premis agent' do
        agent_id = descriptor.find_first("//P:event[P:eventType = 'virus check']/P:linkingAgentIdentifier/P:linkingAgentIdentifierValue", NS_PREFIX).content
        descriptor.find("//P:agent/P:agentIdentifier/P:agentIdentifierValue = '#{agent_id}'", NS_PREFIX).should be_true
      end

    end

    context "dmd" do

      it 'should have mods dmd in a dmdSec with MDTYPE = MODS' do
        descriptor.find("//M:dmdSec/M:mdWrap[M:xmlData/mods:*]/@MDTYPE = 'MODS'", NS_PREFIX).should be_true
      end

    end

  end

  context "the tarball" do

    let :tar_sha1s do
      tdir = Dir.mktmpdir
      `tar xf #{wip.tarball_file} -C #{tdir}`
      $?.exitstatus.should == 0

      Dir.chdir tdir do
        p = File.join *%W(#{wip.id} ** *)
        fs = Dir[p].select { |f| File.file? f }

        fs.inject({}) do |acc, f|
          acc[f] = Digest::SHA1.file(f)
          acc
        end

      end

    end

    it "should have the descriptor" do
      file = File.join wip.id, Wip::DESCRIPTOR_FILE
      tar_sha1s[file].should == Digest::SHA1.file(wip.aip_descriptor_file)
    end

    it "should have all the datafiles" do

      wip.all_datafiles.each do |df|
        file = File.join wip.id, df['aip-path']
        tar_sha1s[file].should == Digest::SHA1.file(df.data_file)
      end

    end

    it "should have the xmlres tarball in the tarball" do
      file = File.join wip.id, "#{Wip::XML_RES_TARBALL_BASENAME}-0.tar"
      tar_sha1s[file].hexdigest.should == Digest::SHA1.file(wip.xmlres_file).hexdigest
    end

    it "should have uploaded the tarball" do

      Tempfile.new 'upload' do |tf|
        lambda { aip.copy.download tf.path }.should_not raise_error
      end

      aip.copy.size.should == File.size(wip.tarball_file)
      aip.copy.sha1.should == Digest::SHA1.file(wip.tarball_file).hexdigest
      aip.copy.md5.should == Digest::MD5.file(wip.tarball_file).hexdigest
    end

  end

end
