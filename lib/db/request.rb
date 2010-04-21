require 'dm-core'
require 'dm-types'

class Request
  include DataMapper::Resource

   property :id, Serial
   property :ieid, String, :required => true
   property :account, String, :required => true
   property :timestamp, DateTime, :required => true
   property :is_authorized, Boolean, :required => true
   property :status, Enum[:enqueued, :released_to_workspace], :default => :enqueued
   property :request_type, Enum[:disseminate, :withdraw, :peek]
   property :agent_identifier, String, :required => true
end
