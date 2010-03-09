require 'db/operations_agents'

def sha1 string
  return Digest::SHA1.hexdigest(string)
end

def add_account name = "Florida Digital Archive", code = "FDA"
  a = Account.new
  a.attributes = { :name => name,
    :code => code }
  a.save or raise "save failed"
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
  c.save or raise "save failed"
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

  k = AuthenticationKey.new
  k.attributes = { :auth_key => sha1(key) }

  o.authentication_key = k
  o.save or raise "save failed"
end

def add_service account, key = "service"
  s = Service.new  
  s.attributes = { :description => "description service",
    :active_start_date => Time.at(0),
    :active_end_date => Time.now + (86400 * 365),
    :identifier => "http://describe.dev.daitss.fcla.edu", }

  s.account = account

  k = AuthenticationKey.new
  k.attributes = { :auth_key => sha1(key) }

  s.authentication_key = k
  s.save or raise "save failed"
end

def add_program account, key = "program"
  p = Program.new  
  p.attributes = { :description => "disseminate program",
    :active_start_date => Time.at(0),
    :active_end_date => Time.now + (86400 * 365),
    :identifier => "darchive:/usr/lib/ruby/gems/daitss/bin/disseminate", }

  p.account = account

  k = AuthenticationKey.new
  k.attributes = { :auth_key => sha1(key) }

  p.authentication_key = k
  p.save or raise "save failed"
end

