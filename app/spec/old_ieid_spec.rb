require 'old_ieid'

describe OldIeid do

  it "should return an IEID that matches the DAITSS 1 format" do
    OldIeid.get_next.should match /E\w{8}_\w{6}/
  end 

  # generate a lot of these as fast as possible and check for collsions
  it "should not generate any collisions" do
    a = []
    dupe = false

    for i in 1..1000
      a.push OldIeid.get_next
    end

    r = a.inject do |i, ieid|
      if i == ieid or i == "dupe"
        "dupe"
      else 
        ieid
      end
    end

    r.should_not == "dupe"
  end
end
