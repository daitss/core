require 'dm-core'
require 'dm-types'
require 'dm-validations'

require 'daitss/db/ops/accounts'
require 'daitss/db/ops/keys'
require 'daitss/db/ops/operations_events'
require 'daitss/db/ops/request'

# TODO: add notes field to OperationsAgent to hold version info
# TODO: remove id field?
class OperationsAgent
  include DataMapper::Resource

  property :id, Serial, :key => true
  property :description, String, :length => 256
  property :active_start_date, DateTime
  property :active_end_date, DateTime
  property :type, Discriminator
  property :identifier, String, :unique_index => true, :length => 100

  # TODO: add constraint
  has 1, :authentication_key
  has n, :operations_events
  belongs_to :account
  has n, :requests
end

class User < OperationsAgent
  property :first_name, String
  property :last_name, String
  property :email, String
  property :phone, String
  property :address, String
end

class Contact < User #Rename to Affiliate
  property :permissions, Flag[:disseminate, :withdraw, :peek, :submit] # add request report
end

class Operator < User; end

class Service < OperationsAgent; end

class Program < OperationsAgent

  def Program.system_agent
    p = Program.first :identifier => 'SYSTEM', :account => Account.system_account

    unless p
      p = Program.new :identifier => 'SYSTEM', :account => Account.system_account
      p.save or raise "cannot save system agent"
    end

    p
  end

end
