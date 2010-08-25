require 'dm-core'

require 'daitss/model/sip'
require 'daitss/model/agent'

class Event
  include DataMapper::Resource

  property :id, Serial, :key => true
  property :name, String, :required => true
  property :timestamp, DateTime, :required => true, :default => proc { DateTime.now }
  property :notes, Text

  belongs_to :agent
  belongs_to :package
end
