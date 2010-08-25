require 'dm-core'
require 'dm-types'
require 'dm-validations'

require 'daitss/model/account'
require 'daitss/model/event'
require 'daitss/model/request'

class Agent
  include DataMapper::Resource

  property :id, String, :key => true
  property :description, Text
  property :auth_key, Text

  property :type, Discriminator
  property :active, ParanoidBoolean

  has n, :events
  has n, :requests

  belongs_to :account
end

class User < Agent
  property :first_name, String
  property :last_name, String
  property :email, String
  property :phone, String
  property :address, String
end

class Contact < User
  property :permissions, Flag[:disseminate, :withdraw, :peek, :submit, :report]
end

class Operator < User; end

class Service < Agent; end

class Program < Agent

  def Program.system_agent
    p = Program.first :identifier => 'SYSTEM', :account => Account.system_account

    unless p
      p = Program.new :identifier => 'SYSTEM', :account => Account.system_account
      p.save or raise "cannot save system agent"
    end

    p
  end

end
