require 'dm-core'
require 'dm-validations'
require 'db/operations_agents'
require 'db/projects'
require 'db/request'

class Account
  include DataMapper::Resource

  property :id, Serial, :key => true
  property :name, String, :required => true
  property :code, String, :required => true, :unique_index => true

  has n, :operations_agents
  has n, :projects
  has n, :requests

  def Account.system_account
    a = Account.first :code => 'SYSTEM'

    unless a
      a = Account.new :code => 'SYSTEM', :name => 'account for system operations'
      a.save or raise "cannot save system account"
    end

    a
  end

end

