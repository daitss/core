require 'spec_helper'
require 'archive'

describe "ingest command line tool" do
  
  describe "arguments" do
    it "should take one argument (ieid)"
    it "should reject if there are 0 arguments"
    it "should reject if there are more than 1 arguments"
  end
  
  describe "environment" do
    it "should have the base url of the archive available"
  end
  
  describe "ways to fail" do
    it "should report when a package does not exist"
    it "should report a rejected package"
    it "should report a snafu package"
    it "should report when there is a systemic problem"
  end
  
end