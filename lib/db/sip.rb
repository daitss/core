require 'data_mapper'

class SubmittedSip
  include DataMapper::Resource

  property :id, Serial, :key => true
  property :package_name, String, :key => true
  property :package_size, Integer, :min => 0, :max => 2**64-1
  property :number_of_datafiles, Integer, :min => 0, :max => 2**64-1
  property :ieid, String

  has n, :operations_events
  has n, :requests
  belongs_to :project, :required => false
end
