require 'dm-core'
require 'dm-validations'

require 'daitss/model/account'
require 'daitss/model/package'

module Daitss

  class Project
    include DataMapper::Resource

    property :id, String, :key => true
    property :description, Text

    property :account_id, String, :key => true

    has 0..n, :packages

    belongs_to :account, :key => true
  end

end
