require 'data_mapper'
require 'dm-is-list'

require 'daitss/model/account'
require 'daitss/model/agent'
require 'daitss/model/sip'

class Request
  include DataMapper::Resource

   property :id, Serial, :key => true

   # what does this record? better name could be X_at?
   property :timestamp, DateTime, :required => true, :default => proc { DateTime.now }
   property :is_authorized, Boolean, :required => true
   property :status, Enum[:enqueued, :released_to_workspace], :default => 1 # default => :enqueued
   property :request_type, Enum[:disseminate, :withdraw, :peek]

   belongs_to :agent
   belongs_to :package

   # TODO not sure how this quite works, but investigate
   is :list, :scope => [:package_id]
end
