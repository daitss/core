# represents an admin log entry
class AdminLog
  include DataMapper::Resource

  property :id, Serial
  property :timestamp, DateTime, :default => proc { DateTime.now }, :required => true
  property :message, Text, :required => true
end
