require 'daitss/proc/wip/tarball'
require 'daitss/xmlns'
require 'daitss/proc/datafile/describe'
require 'daitss/proc/datafile/actionplan'

require 'daitss/model/aip'

include Daitss

describe DataFile do

  describe "with no preservation actions" do

    before :all do
      wip = submit 'mimi'
      @pdf = wip.original_datafiles.find { |df| df['aip-path'] == File.join(Wip::SIP_FILES_DIR, 'mimi.pdf') }
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
      @wave = wip.original_datafiles.find { |df| df['aip-path'] == File.join(Wip::SIP_FILES_DIR, 'obj1.wav') }
      @wave.describe!
      @norm = @wave.normalization
    end

    it 'should have the normalization id' do
      @norm['normalization'].should == 'wave_norm'
    end

    it 'should have coded' do
      @norm['codec'].should == 'PCM'
    end

    it 'should have format' do
      @norm['format'].should == 'Waveform Audio'
    end

    it 'should have format version' do
      @norm['format version'].should == 'None'
    end

    it 'should have revision date' do
      @norm['revision date'].should == '2010.09.16'
    end

  end

  describe 'with a xmlresolution' do

    before :all do
      wip = submit 'wave'
      @xml = wip.original_datafiles.find { |df| df['aip-path'] == File.join(Wip::SIP_FILES_DIR, 'wave.xml') }
      @xml.describe!
    end

    it 'should not be nil' do
      @xml.xmlresolution.should_not be_nil
    end

  end

end
