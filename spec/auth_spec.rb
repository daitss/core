require 'daitss-auth'
require 'digest/sha1'
require 'pp'

describe Authentication do

  before(:each) do
    DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/data/daitss-core.db")
    DataMapper.auto_migrate!
  end


  def add_account name = "FDA", code = "FDA"
    a = Account.new
    a.attributes = { :name => name,
                     :code => code }
    a.save
    return a
  end

  def add_contact account, key = "foobar"
    c = Contact.new
    c.attributes = { :description => "contact",
                     :active_start_date => Time.at(0),
                     :active_end_date => Time.now + (86400 * 365),
                     :identifier => "foobar",
                     :first_name => "Foo",
                     :last_name => "Bar",
                     :email => "foobar@ufl.edu",
                     :phone => "555-5555",
                     :address => "123 Toontown",
                     :permissions => [:disseminate, :withdraw, :submit, :peek] }

    c.account = account

    k = AuthenticationKey.new
    k.attributes = { :auth_key => sha1(key) }

    c.authentication_key = k
    c.save
  end

  def add_operator account, key = "barbaz"
    o = Operator.new  
    o.attributes = { :description => "operator",
                     :active_start_date => Time.at(0),
                     :active_end_date => Time.now + (86400 * 365),
                     :identifier => "operator",
                     :first_name => "Op",
                     :last_name => "Perator",
                     :email => "operator@ufl.edu",
                     :phone => "666-6666",
                     :address => "FCLA" }

    o.account = account

    k = AuthorizationKey.new
    k.attributes = { :auth_key => sha1(key) }

    o.authentication_key = k
    o.save
  end

  def sha1 string
    return Digest::SHA1.hexdigest(string)
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
    auth_result.metadata["account_id"].should == 1
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
end
