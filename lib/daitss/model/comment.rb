require 'dm-core'

require 'daitss/model/event'
require 'daitss/model/agent'

module Daitss

  class Comment
    include DataMapper::Resource

    property :id, Serial, :key => true
    property :text, Text, :required => true
    property :timestamp, DateTime, :required => true, :default => proc { DateTime.now }

    belongs_to :agent
    belongs_to :event
  end
end
