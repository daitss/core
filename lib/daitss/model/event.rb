require 'dm-core'

require 'daitss/model/agent'
require 'daitss/model/package'

module Daitss

  class Event
    include DataMapper::Resource

    property :id, Serial, :key => true
    property :name, String, :required => true
    property :timestamp, DateTime, :required => true, :default => proc { DateTime.now }
    property :notes, Text

    belongs_to :agent
    belongs_to :package
  end

end
