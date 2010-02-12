require 'daitss-auth'
require 'digest/sha1'

describe Authentication do

  before(:each) do
    DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/data/daitss-core.db")
    DataMapper.auto_migrate!
  end

  def add_contact key = "foobar"
    a = Account.new
    a.attributes = { :name => "UF",
                     :code => "UF" }
    a.save

    c = Contact.new
    c.attributes = { :description => "contact",
                     :active_start_date => 0,
                     :active_end_date => 0,
                     :username => "foobar",
                     :first_name => "Foo",
                     :last_name => "Bar",
                     :email => "foobar@ufl.edu",
                     :phone => "555-5555",
                     :address => "123 Toontown",
                     :permissions => :disseminate,
                     :permissions => :withdraw,
                     :permissions => :submit,
                     :permissions => :peek }

    c.account = a

    k = Key.new
    k.attributes = { :key => Digest::SHA1.hexdigest(key) }
    k.operations_agent = c


    puts k.methods
    
    k.save
    c.save
  end

  it "should correctly authenticate a contact" do
    puts "foo"
    add_contact
  end
end
