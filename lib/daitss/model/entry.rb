require 'data_mapper'

# represents an admin log entry
class Entry
  include DataMapper::Resource

  property :id, Serial
  property :timestamp, DateTime, :default => proc { DateTime.now }, :required => true
  property :message, Text, :required => true
end
