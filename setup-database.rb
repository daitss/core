#!/usr/bin/env ruby

require 'dm-core'
require 'dm-core'
require 'db/operations_agents'
require 'db/operations_events'
require 'db/accounts'
require 'db/projects'
require 'db/keys'
require 'digest/sha1'

DataMapper.setup(:default, "sqlite3://#{Dir.pwd}/data/submission_svc_test.db")

DataMapper.auto_migrate!

# add an FDA account
a = Account.new
a.attributes = { :name => "FDA",
                 :code => "FDA" }
a.save!

# add an operator user 

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

o.account = a

k = AuthenticationKey.new
k.attributes = { :auth_key => Digest::SHA1.hexdigest("operator") }

o.authentication_key = k
o.save!

# add a contact lacking permissions to submit

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
  :permissions => [:disseminate, :withdraw, :peek] }

c.account = a

j = AuthenticationKey.new
j.attributes = { :auth_key => Digest::SHA1.hexdigest("foobar") }

c.authentication_key = j
c.save!

