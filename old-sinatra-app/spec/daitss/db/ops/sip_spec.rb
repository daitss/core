require 'daitss/model/sip'

describe Sip do

  it "should return an IEID that matches the DAITSS 1 format" do
    Package.new.id.should match /E\w{8}_\w{6}/
  end

  # generate a lot of these as fast as possible and check for collsions
  # SMELL this doesn't really address people checking at the same time
  it "should not generate any collisions" do
    ids = (1..1000).map { Package.new.id }
    ids.size.should == ids.uniq.size
  end

end
