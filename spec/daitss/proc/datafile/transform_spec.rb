require 'spec_helper'
require 'daitss/proc/wip/tarball'
require 'daitss/proc/datafile/describe'
require 'daitss/proc/datafile/transform'

describe DataFile do

  describe 'transformation service interaction' do
    subject { submit 'wave' }

    it "should raise an error if the url is not a success" do
      lambda {
        subject.original_datafiles.first.ask_transformation_service 'http://localhost/foo/bar'
      }.should raise_error(/Not Found/)
    end

    it "should get back an array of data and an extension if the transformation is good" do
      f = subject.original_datafiles.find { |f| f['aip-path'] =~ %r{\.wav$} }
      agnet, event, data, ext = f.ask_transformation_service 'wave_norm'
      data.should_not be_empty
      ext.should == '.wav'
    end

  end

  describe 'migration' do

    before :all do
      wip = submit 'wave'
      @source = wip.original_datafiles.find { |odf| odf['aip-path'] == File.join(Wip::SIP_FILES_DIR, 'obj1.wav') }
      @source.describe!
      @source.migrate!
      @df = @source.migrated_version
    end

    it 'should have aip path' do
      pending 'need migratable sip'
      @df['aip-path'].should == "#{@df.id}.wav"
    end

    it 'should have transformation metadata' do
      pending 'need migratable sip'
      @df['transformation'].should == 'wave_norm'
    end

    it 'should have a transformation source' do
      pending 'need migratable sip'
      @df['transformation-source'].should == @source.uri
    end

    it 'should have a transformation strategy' do
      pending 'need migratable sip'
      @df['transformation-strategy'].should == 'migrate'
    end

  end

  describe 'normalization' do

    before :all do
      wip = submit 'wave'
      @source = wip.original_datafiles.find { |odf| odf['aip-path'] == File.join(Wip::SIP_FILES_DIR, 'obj1.wav') }
      @source.describe!
      @source.normalize!
      @df = @source.normalized_version
    end

    it 'should have aip path' do
      @df['aip-path'].should == File.join(Wip::AIP_FILES_DIR, "#{@df.id}.wav")
    end

    it 'should have normalize agent' do
      @df.should have_key('normalize-agent')
      doc = XML::Document.string @df['normalize-agent']
      doc.find_first "/P:agent", NS_PREFIX
    end

    it 'should have normalize event' do
      @df.should have_key('normalize-event')
      doc = XML::Document.string @df['normalize-event']
      doc.find_first "/P:event", NS_PREFIX
    end

    it 'should have some action plan info in the normalize event' do
      doc = XML::Document.string @df['normalize-event']
      detail = doc.find_first "/P:event/P:eventDetail", NS_PREFIX
      detail.content.should include('normalization: wave_norm')
      detail.content.should include('codec: PCM')
      detail.content.should include('format: Waveform Audio')
      detail.content.should include('format version: None')
      detail.content.should include('revision date: 2010.09.16')
    end

    it 'should have a transformation source' do
      @df['transformation-source'].should == @source.uri
    end

    it 'should have a transformation strategy' do
      @df['transformation-strategy'].should == 'normalize'
    end

  end

end
