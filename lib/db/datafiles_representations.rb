class DatafileRepresentation
  include DataMapper::Resource
  property :id, Serial, :key => true
  property :datafile_id, String, :length => 100
  property :representation_id, String, :length => 100
  belongs_to :datafile
  belongs_to :representation
end