require 'dm-core'
require 'dm-validations'

require 'daitss/db/int_entity'
require 'daitss/model/account'
require 'daitss/model/sip'

class Project
  include DataMapper::Resource

  property :id, Serial
  property :name, String, :required => true
  property :code, String, :required => true, :unique_index => true

  belongs_to :account

  # SMELL these are 1-1 to each other should link to one not both
  has 0..n, :sips
  has 0..n, :intentities
end
