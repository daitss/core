require 'dm-core'
require 'dm-types'
require 'db/keys.rb'
require 'db/operations_events.rb'
require 'db/accounts.rb'

class OperationsAgent
  include DataMapper::Resource

  property :id, Serial
  property :description, String
  property :active_start_date, DateTime
  property :active_end_date, DateTime
  property :type, Discriminator
  property :identifier, String, :unique => true

  has 1, :authentication_key
  has n, :operations_events
  belongs_to :account
end

class User < OperationsAgent
  property :first_name, String
  property :last_name, String
  property :email, String
  property :phone, String
  property :address, String
end

class Contact < User
  property :permissions, Flag[:disseminate, :withdraw, :peek, :submit]
end

class Operator < User; end

class Service < OperationsAgent; end

class Program < OperationsAgent; end
