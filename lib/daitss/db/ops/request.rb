require 'dm-core'
require 'dm-types'
require 'db/accounts'
require 'db/operations_agents'
require 'db/sip'

class Request
  include DataMapper::Resource

   property :id, Serial, :key => true
   property :timestamp, DateTime, :required => true
   property :is_authorized, Boolean, :required => true
   property :status, Enum[:enqueued, :released_to_workspace], :default => 1 # default => :enqueued
   property :request_type, Enum[:disseminate, :withdraw, :peek]

   belongs_to :operations_agent
   belongs_to :account
   belongs_to :submitted_sip
end
