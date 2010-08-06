require 'rubygems'
require 'namespaces'


require 'dm-core'
require 'dm-types'
require 'dm-aggregates'
require 'dm-constraints'
require "dm-validations"

require 'db/agent'
require 'db/audio'
require 'db/image'
require 'db/document'
require 'db/text'
require 'db/objectformat'
require 'db/format'
require 'db/bitstream'
require 'db/severe_element'
require 'db/brokenlinks'
require 'db/datafile'
require 'db/datafile_severe_element'
require 'db/events'
require 'db/int_entity'
require 'db/message_digest'
require 'db/relationship'

# ops database
require 'db/accounts'
require 'db/keys'
require 'db/operations_agents'
require 'db/operations_events'
require 'db/projects'
require 'db/sip'

# request
require 'db/request'

# boss
require 'stashbin.rb'

# methods to add accounts and ops agents to database
module Daitss

  def add_account name = "FDA", code = "FDA"
    a = Account.new

    a.attributes = {
      :name => name,
      :code => code
    }

    a.save!
    return a
  end

  def add_project account,  name = "FDA", code = "FDA"
    p = Project.new
    p.attributes = { :name => name,
                     :code => code }

    p.account = account
    p.save!

    return p
  end

  def add_operator account, identifier = "operator", password = "operator"
    o = Operator.new

    o.attributes = {
      :description => "operator",
      :active_start_date => Time.at(0),
      :active_end_date => Time.now + (86400 * 365),
      :identifier => identifier,
      :first_name => "Op",
      :last_name => "Perator",
      :email => "operator@ufl.edu",
      :phone => "666-6666",
      :address => "FCLA"
    }

    o.account = account
    k = AuthenticationKey.new
    k.attributes = { :auth_key => Digest::SHA1.hexdigest(password) }
    o.authentication_key = k
    o.save!
    return o
  end


  def add_contact account, permissions = [:disseminate, :withdraw, :peek, :submit], identifier = "contact", password = "contact"
    c = Contact.new

    c.attributes = {
      :description => "contact",
      :active_start_date => Time.at(0),
      :active_end_date => Time.now + (86400 * 365),
      :identifier => identifier,
      :first_name => "Foo",
      :last_name => "Bar",
      :email => "foobar@ufl.edu",
      :phone => "555-5555",
      :address => "123 Toontown",
      :permissions => permissions
    }

    c.account = account
    j = AuthenticationKey.new
    j.attributes = { :auth_key => Digest::SHA1.hexdigest(password) }
    c.authentication_key = j
    c.save!
    return c
  end
end
