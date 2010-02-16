require 'dm-core'
require 'db/operations_agents'
require 'db/projects'

class Account
  include DataMapper::Resource

  property :id, Serial
  property :name, String, :nullable => false
  property :code, String, :nullable => false

  has n, :contacts
  has n, :projects
end
