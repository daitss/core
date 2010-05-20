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

  def Account.operations_account
    a = Account.first :code => 'OP'

    unless a
      a = Account.new :code => 'OP', :name => 'account for operations'
      a.save or raise "cannot save operations account"
    end

    a
  end

end

