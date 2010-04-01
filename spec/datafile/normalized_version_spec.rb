require 'spec_helper'
require 'wip/ingest'
require 'datafile/normalized_version'

describe DataFile do

  subject do
    wip = submit 'wave'
    wip.ingest!
    wip
  end

  describe "that has a normalized version" do

    it "should return the datafile that was generated via normalization" do
      wav = subject.datafiles.find { |df| df['sip-path'] == 'obj1.wav' }
      norm = subject.datafiles.find { |df| df['aip-path'] == '0-normalization.wav' }
      wav.normalized_version.should be_nil
      wav.normalized_version = norm
      wav.normalized_version.should == norm
    end

  end

end
