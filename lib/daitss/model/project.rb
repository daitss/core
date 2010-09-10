require 'dm-core'
require 'dm-validations'

require 'daitss/db/int_entity'
require 'daitss/model/account'
require 'daitss/model/sip'

class Project
  include DataMapper::Resource

  property :id, String, :key => true
  property :description, Text

  has 0..n, :packages

  belongs_to :account, :key => true
end
