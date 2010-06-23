require "rubygems"
require "bundler"
Bundler.setup

require 'daitss2'

def add_account name = "FDA", code = "FDA"

  existing = Account.first(:code => code)
  return existing if existing

  a = Account.new
  a.attributes = { :name => name,
                   :code => code }
  a.save!

  return a
end

def add_project account, name = "PRJ", code = "PRJ"

  existing = Project.first(:code => code)
  return existing if existing

  p = Project.new
  p.attributes = { :name => name,
                   :code => code }

  p.account = account
  p.save!

  return p
end

def add_operator account, identifier = "operator", password = "operator"
  o = Operator.new

  o.attributes = { :description => "operator",
    :active_start_date => Time.at(0),
    :active_end_date => Time.now + (86400 * 365),
    :identifier => identifier,
    :first_name => "Op",
    :last_name => "Perator",
    :email => "operator@ufl.edu",
    :phone => "666-6666",
    :address => "FCLA" }

  o.account = account

  k = AuthenticationKey.new
  k.attributes = { :auth_key => Digest::SHA1.hexdigest(password) }

  o.authentication_key = k
  o.save!

  return o
end


def add_contact account, permissions = [:disseminate, :withdraw, :peek, :submit], identifier = "contact", password = "contact"
  c = Contact.new
  c.attributes = { :description => "contact",
    :active_start_date => Time.at(0),
    :active_end_date => Time.now + (86400 * 365),
    :identifier => identifier,
    :first_name => "Foo",
    :last_name => "Bar",
    :email => "foobar@ufl.edu",
    :phone => "555-5555",
    :address => "123 Toontown",
    :permissions => permissions  }

  c.account = account

  j = AuthenticationKey.new
  j.attributes = { :auth_key => Digest::SHA1.hexdigest(password) }

  c.authentication_key = j
  c.save!

  return c
end

