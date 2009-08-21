require 'spec_helper'

describe "aip descriptor" do
  
  before :each do
    aip = aip_instance_from_sip 'ateam'
    aip.ingest!
    aip.should_not be_snafu
    aip.should_not be_rejected
    @descriptor = aip.mono_descriptor_file
  end
  
  it "should compact the descriptor into a single file" do
    @descriptor.should exist_on_fs
  end

  it "should validate against its schema" do
    @descriptor.should be_valid_xml
  end
  
  it "should pass PREMIS in METS best practice" do
    pending 'waiting for stron integration'
    @descriptor.should conform_to_pim_bp
  end
  
  # it "should have globally unique identifiers (across the FDA) for events agents and objects"
  # it "We need to add representations, next iteration"
  # 
  # describe "premis containers" do
  #   it "should reside in its own mets container"
  #   it "should be part of the premis namespace"
  # end
  #   
  # it "should only have top level validation events, checksum check and failure events only"
  # it "should only have external provenance events if it is found"
  # it "should only have representation retrieval if it is found"
  # it "should only have eventOutcomeDetail if there are anomalies to report"
  # it "should not have an action plan event"
  # 
end