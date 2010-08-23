require 'dm-core'

require 'daitss/db/ops/agent'

class AuthenticationKey
  include DataMapper::Resource

  property :id, Serial, :key => true
  property :auth_key, Text

  belongs_to :operations_agent
end
