require 'operations_agents'
require 'projects'

class Accounts
  include DataMapper::Resource

  property :id, Serial
  property :name, String, :nullable => false
  property :code, String, :nullable => false

  has n, :contact
  has n, :project
end
