require 'spec_helper'
require 'set'

describe "aip descriptor" do
  
  before :all do
    @aip = aip_instance_from_sip 'wave'
    @aip.ingest!
    @aip.should_not be_snafu
    @aip.should_not be_rejected
  end
  
  after :all do
    nuke_sandbox!
  end
  
  subject do
    @aip.mono_descriptor_file
  end
  
  it { should exist_on_fs }
  it { pending 'tcf schemalocation is unavailable'; should be_valid_xml }
  it { pending 'package level metadata requires a representation, structMap will reference the rep'; should conform_to_pim_bp }
  it { should have_r0_representation }
  it { should have_rC_representation }
  
  it "should use mets file/@ID for all premis file object ids" do
    doc = XML::Document.file subject
    xpath = "//premis:object[@xsi:type='file']/premis:objectIdentifier/premis:objectIdentifierValue"
    premis_ids = doc.find(xpath, NS_MAP).map { |node| node.content.strip }
    mets_ids = doc.find("//mets:file/@ID", NS_MAP).map { |node| node.value.strip }
    mets_ids.to_set.should == premis_ids.to_set
  end
  
  it "should have r0 without products of transformations" do
    pending 'not all transformation md is available'
    r_0_files(@descriptor).to_s.should == transformations(@descriptor).keys.to_set
  end

  it "should have rC with products of transformations replacing predecessors" do
    pending 'not all transformation md is available'
    r_c_files(@descriptor).to_s.should == transformations(@descriptor).values.to_set
  end

  it "should have a transformed file" do
    doc = XML::Document.file subject
    files = doc.find("//mets:file", NS_MAP).map { |node| node['ID'] }
    files.size.should == 3

    # there should be a transformation event
    doc.find_first("//premis:event[premis:eventType = 'Service::Transform::Normalization']", NS_MAP).should_not be_nil
    doc.find("//premis:event[premis:eventType = 'Service::Transform::Normalization']", NS_MAP).each do |event_node|
      event_node.should_not be_nil

      # it should link to an object
      loi = event_node.find_first "premis:linkingObjectIdentifier[premis:linkingObjectIdentifierType ='d2']/premis:linkingObjectIdentifierValue", NS_MAP
      loi.should_not be_nil
      src_id = loi.content.strip

      # there should be a source
      src = doc.find_first("//#{Premis::object "d2", src_id }", NS_MAP)
      src.should_not be_nil
      
      # and a dest
      ei = event_node.find_first "premis:eventIdentifier", NS_MAP
      ei.should_not be_nil
      
      eit = ei.find_first 'premis:eventIdentifierType', NS_MAP
      eit.should_not be_nil
      
      eiv = ei.find_first 'premis:eventIdentifierValue', NS_MAP
      eiv.should_not be_nil

      dst = doc.find_first("//premis:object/premis:linkingEventIdentifier[premis:linkingEventIdentifierType = '#{eit.content.strip}' and premis:linkingEventIdentifierValue = '#{eiv.content.strip}']", NS_MAP)
      dst.should_not be_nil
    end
    
  end
  
  # it "should only have top level validation events, checksum check and failure events only"
  # it "should only have external provenance events if it is found"
  # it "should only have representation retrieval if it is found"
  # it "should only have eventOutcomeDetail if there are anomalies to report"
  # it "should not have an action plan event"
  # 
end