require 'dm-core'

# TODO: this should probably have an association the the Intentity table, not a string for IEID

class PackageLocation
  include DataMapper::Resource

  property :id, Serial
  property :timestamp, DateTime, :required => true
  property :path, String, :required => true
  property :ieid, String, :required => true

  # TODO: tie this to an event
end
