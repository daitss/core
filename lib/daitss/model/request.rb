require 'data_mapper'
require 'dm-is-list'

require 'daitss/model/account'
require 'daitss/model/agent'
require 'daitss/model/sip'

class Request
  include DataMapper::Resource
   property :id, Serial, :key => true
   property :note, Text

   property :timestamp, DateTime, :required => true, :default => proc { DateTime.now }
   property :is_authorized, Boolean, :required => true, :default => false
   property :status, Enum[:enqueued, :released_to_workspace], :default => :enqueued
   property :type, Enum[:disseminate, :withdraw, :peek]

   belongs_to :agent
   belongs_to :package

   is :list, :scope => [:package_id]
end
