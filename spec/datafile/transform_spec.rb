require 'spec_helper'
require 'datafile/describe'
require 'datafile/transform'

describe DataFile do

  describe 'transformation service interaction' do
    subject { submit 'wave' }

    it "should raise an error if the url is not a success" do
      lambda {
        subject.original_datafiles.first.transform 'http://localhost/foo/bar'
      }.should raise_error(/Not Found/)
    end

    it "should get back an array of data and an extension if the transformation is good" do
      data, ext = subject.original_datafiles.first.transform 'http://localhost:7000/transformation/transform/wave_norm'
      data.should_not be_empty
      ext.should == '.wav'
    end

  end

  describe 'migration' do

    before :all do
      wip = submit 'wave'
      @source = wip.original_datafiles.find { |odf| odf['aip-path'] == 'obj1.wav' }
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
      @df['transformation-url'].should == 'http://localhost:7000/transformation/transform/wave_norm'
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
      @source = wip.original_datafiles.find { |odf| odf['aip-path'] == 'obj1.wav' }
      @source.describe!
      @source.normalize!
      @df = @source.normalized_version
    end

    it 'should have aip path' do
      @df['aip-path'].should == "#{@df.id}.wav"
    end

    it 'should have transformation agent' do
      @df['transformation-agent'].should == 'http://localhost:7000/transformation/transform/wave_norm'
    end

    it 'should have a transformation source' do
      @df['transformation-source'].should == @source.uri
    end

    it 'should have a transformation strategy' do
      @df['transformation-strategy'].should == 'normalize'
    end

  end

end
