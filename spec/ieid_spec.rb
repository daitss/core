require 'ieid'

describe Ieid do
 it "should generate an valid ieid" do
   Ieid.new.to_s.should =~ /[\da-z]{4}-[\da-z]{4}-[\da-z]{4}-[\da-z]{4}-[\da-z]{4}-[\da-z]{5}/
 end 
end
