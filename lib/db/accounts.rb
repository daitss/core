require 'dm-core'
require 'db/operations_agents'
require 'db/projects'
require 'db/request'

class Account
  include DataMapper::Resource

  property :id, Serial
  property :name, String, :required => true
  property :code, String, :required => true, :unique => true

  has n, :operations_agents
  has n, :projects
  has n, :requests
end
