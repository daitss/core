require 'spec_helper'
require 'aip'

describe Aip do
  
  it "should validate" do
    aip = aip_instance 'good'
    aip.should_not be_validated
    lambda { aip.validate }.should_not raise_error(Reject)
    aip.should be_validated
  end

  it "should raise a rejection error if validation fails" do
    aip = aip_instance 'invalid-descriptor'
    aip.should_not be_validated
    lambda { aip.validate }.should raise_error(Reject)
    aip.should be_validated
  end
  
  it "should collect incoming provenance" do
    aip = aip_instance 'preexisting-digiprov'
    aip.should_not be_provenance_retrieved
    aip.retrieve_provenance
    aip.should be_provenance_retrieved
  end

  it "should collect incoming tipr provenance" do
    aip = aip_instance_from_sip 'rxp'
    aip.should_not be_rxp_provenance_retrieved
    aip.retrieve_rxp_provenance
    aip.should be_rxp_provenance_retrieved
    aip.should_not be_provenance_retrieved
  end
  
  it "should collect incoming representations" do
    aip = aip_instance_from_sip 'incoming-reps'
    aip.should_not be_representations_retrieved
    aip.retrieve_representations
    aip.should be_representations_retrieved
  end
  
end
