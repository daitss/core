require 'spec_helper'
require 'wip/ingest'
require 'datafile/normalized_version'

describe DataFile do

  subject do
    wip = submit_sip 'mimi'
    wip.ingest!
    wip
  end

  describe "that has a normalized version" do

    it "should return the datafile that was generated via normalization" do
      pdf = subject.datafiles.find { |df| df['sip-path'] == 'mimi.pdf' }
      tif = subject.datafiles.find { |df| df['aip-path'] == '0-normalization.tif'}
      pdf.normalized_version.should be_nil
      pdf.normalized_version = tif
      pdf.normalized_version.should == tif
    end

  end

end
