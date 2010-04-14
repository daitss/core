require 'dm-core'
require 'db/accounts'

class Project
  include DataMapper::Resource

  property :id, Serial
  property :name, String, :required => true
  property :code, String, :required => true
  
  belongs_to :account
  has 0..n, :intentities
end
