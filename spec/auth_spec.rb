require 'daitss-auth'
require 'digest/sha1'
require 'helper'
require 'spec_helper'
require 'pp'

describe Authentication do

  before :each do
    DataMapper.auto_migrate!
  end

  it "should authenticate a contact when good credentials are provided" do
    a = add_account "University of Florida", "UF"
    add_contact a

    auth_result = Authentication.authenticate("foobar", "foobar")

    auth_result.valid.should == true
    auth_result.active.should == true
    
    auth_result.metadata["agent_type"].should == :contact
    auth_result.metadata["description"].should == "contact"
    auth_result.metadata["first_name"].should == "Foo"
    auth_result.metadata["last_name"].should == "Bar"
    auth_result.metadata["email"].should == "foobar@ufl.edu"
    auth_result.metadata["phone"].should == "555-5555"
    auth_result.metadata["address"].should == "123 Toontown"
    auth_result.metadata["can_disseminate"].should == true
    auth_result.metadata["can_withdraw"].should == true
    auth_result.metadata["can_peek"].should == true
    auth_result.metadata["can_submit"].should == true
    auth_result.metadata["account_code"].should == "UF"
    auth_result.metadata["account_name"].should == "University of Florida"

  end

  it "should authenticate a contact when bad credentials are provided" do
    a = add_account "UF", "UF"
    add_contact a

    auth_result = Authentication.authenticate("foobar", "notthepassword")

    auth_result.valid.should == false
    auth_result.active.should == nil
    auth_result.metadata.should == nil
  end

  it "should authenticate an operator when good credentials are provided" do
    a = add_account
    add_operator a

    auth_result = Authentication.authenticate("operator", "barbaz")

    auth_result.valid.should == true
    auth_result.active.should == true
    
    auth_result.metadata["agent_type"].should == :operator
    auth_result.metadata["description"].should == "operator"
    auth_result.metadata["first_name"].should == "Op"
    auth_result.metadata["last_name"].should == "Perator"
    auth_result.metadata["email"].should == "operator@ufl.edu"
    auth_result.metadata["phone"].should == "666-6666"
    auth_result.metadata["address"].should == "FCLA"
    auth_result.metadata["account_code"].should == "FDA"
    auth_result.metadata["account_name"].should == "Florida Digital Archive"

  end

  it "should authenticate an operator when bad credentials are provided" do
    a = add_account
    add_operator a

    auth_result = Authentication.authenticate("operator", "notthepassword")

    auth_result.valid.should == false
    auth_result.active.should == nil
    auth_result.metadata.should == nil
  end

  it "should authenticate a service when good credentials are provided" do
    a = add_account
    add_service a

    auth_result = Authentication.authenticate("http://describe.dev.daitss.fcla.edu", "service")

    auth_result.valid.should == true
    auth_result.active.should == true
    
    auth_result.metadata["agent_type"].should == :service
    auth_result.metadata["description"].should == "description service"
    auth_result.metadata["account_code"].should == "FDA"
    auth_result.metadata["account_name"].should == "Florida Digital Archive"

  end

  it "should authenticate a service when bad credentials are provided" do
    a = add_account
    add_service a

    auth_result = Authentication.authenticate("http://describe.dev.daitss.fcla.edu", "notthepassword")

    auth_result.valid.should == false
    auth_result.active.should == nil
    auth_result.metadata.should == nil
  end

  it "should authenticate a program when good credentials are provided" do
    a = add_account
    add_program a

    auth_result = Authentication.authenticate("darchive:/usr/lib/ruby/gems/daitss/bin/disseminate", "program")

    auth_result.valid.should == true
    auth_result.active.should == true
    
    auth_result.metadata["agent_type"].should == :program
    auth_result.metadata["description"].should == "disseminate program"
    auth_result.metadata["account_code"].should == "FDA"
    auth_result.metadata["account_name"].should == "Florida Digital Archive"

  end

  it "should authenticate a program when bad credentials are provided" do
    a = add_account
    add_program a

    auth_result = Authentication.authenticate("darchive:/usr/lib/ruby/gems/daitss/bin/disseminate", "notthepassword")

    auth_result.valid.should == false
    auth_result.active.should == nil
    auth_result.metadata.should == nil
  end
end
