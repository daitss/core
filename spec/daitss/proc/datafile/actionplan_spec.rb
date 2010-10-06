require 'spec_helper'
require 'daitss/xmlns'
require 'daitss/proc/datafile/describe'
require 'daitss/proc/datafile/actionplan'

require 'daitss/model/aip'

include Daitss

describe DataFile do

  describe "with no preservation actions" do

    before :all do
      wip = submit 'mimi'
      @pdf = wip.original_datafiles.find { |df| df['aip-path'] == File.join(AipArchive::SIP_FILES_DIR, 'mimi.pdf') }
      @pdf.describe!
    end

    it 'should return nil if there is no migration' do
      @pdf.migration.should be_nil
    end

    it 'should return nil if there is no normalization' do
      @pdf.normalization.should be_nil
    end

    it 'should return nil if there is no xmlresolution' do
      @pdf.xmlresolution.should be_nil
    end

  end

  describe 'with a migration' do
    it 'should redirect to a transformation'
  end

  describe 'with a normalization' do

    before :all do
      wip = submit 'wave'
      @wave = wip.original_datafiles.find { |df| df['aip-path'] == File.join(AipArchive::SIP_FILES_DIR, 'obj1.wav') }
      @wave.describe!
    end

    subject { @wave.normalization }

    it 'should have actionplan event' do
      subject.find("contains(//P:event/P:eventType, 'actionplan')", NS_PREFIX).should be_true
    end

    describe "event outcome" do
      subject { @wave.normalization.find_first("//P:event/P:eventDetail", NS_PREFIX).content }
      it { should include('normalization: wave_norm') }
      it { should include('codec: PCM') }
      it { should include('format: Waveform Audio') }
      it { should include('format version: None') }
      it { should include('revision date: 2010.09.16') }
    end

    it 'should have actionplan agent' do
      subject.find("contains(//P:agent/P:agentName, 'Action Plan Service')", NS_PREFIX).should be_true
    end

  end

  describe 'with a xmlresolution' do

    before :all do
      wip = submit 'wave'
      @xml = wip.original_datafiles.find { |df| df['aip-path'] == File.join(AipArchive::SIP_FILES_DIR, 'wave.xml') }
      @xml.describe!
    end

    it 'should not be nil' do
      @xml.xmlresolution.should_not be_nil
    end

  end

end
