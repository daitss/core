require 'data_mapper'

class SubmittedSip
  include DataMapper::Resource

  property :id, Serial, :key => true
  property :package_name, String, :key => true
  property :package_size, Integer
  property :number_of_datafiles, Integer
  property :ieid, String

  has n, :operations_events
  has n, :requests
  belongs_to :project, :required => false
end
