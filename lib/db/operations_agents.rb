require 'dm-core'
require 'dm-types'
require 'db/keys.rb'
require 'db/operations_events.rb'
require 'db/accounts.rb'

class OperationsAgent
  include DataMapper::Resource

  property :id, Serial
  property :description, String, :nullable => false
  property :active_start_date, DateTime, :nullable => false
  property :active_end_date, DateTime, :nullable => false
  property :type, Discriminator

  has 1, :key
  has n, :operations_events
end

class User < OperationsAgent
  property :username, String, :nullable => false
  property :first_name, String, :nullable => false
  property :last_name, String, :nullable => false
  property :email, String, :nullable => false
  property :phone, String, :nullable => false
  property :address, String, :nullable => false
end

class Contact < User
  property :permissions, Flag[:disseminate, :withdraw, :peek, :submit], :nullable => false

  belongs_to :account
end

class Operator < User; end

class Service < OperationsAgent
  property :url, String, :nullable => false
end

class Program < OperationsAgent
  property :path, String, :nullable => false
end
