require 'dm-types'
require 'keys'
require 'operations_events'
require 'accounts'

class OperationsAgents
  include DataMapper::Resource

  property :id, Serial
  property :description, String, :nullable => false
  property :active_start_date, DateTime, :nullable => false
  property :active_end_date, DateTime, :nullable => false
  property :type, Discriminator

  has 1, :key
  has n, :operations_event
end

class Users < OperationsAgents
  property :username, String, :nullable => false
  property :first_name, String, :nullable => false
  property :last_name, String, :nullable => false
  property :email, String, :nullable => false
  property :phone, String, :nullable => false
  property :address, String, :nullable => false
end

class Contacts < Users
  property :permissions, Flag[:disseminate, :withdraw, :peek, :submit], :nullable => false

  belongs_to :account
end

class Operators < Users; end

class Services < OperationsAgents
  property :url, String, :nullable => false
end

class Programs < OperationsAgents
  property :path, String, :nullable => false
end
