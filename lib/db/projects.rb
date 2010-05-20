require 'dm-core'
require 'dm-validations'
require 'db/accounts'
require 'db/sip'

class Project
  include DataMapper::Resource

  property :id, Serial
  property :name, String, :required => true
  property :code, String, :required => true, :unique_index => true
  
  belongs_to :account
  has 0..n, :submitted_sips
  has 0..n, :intentities
end
