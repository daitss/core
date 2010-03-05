class DatafileSevereElement
  include DataMapper::Resource
  property :id, Serial, :key => true
  # property :datafile_id, String, :length => 100
  # property :severe_element_id, Serial, :length => 100
  belongs_to :datafile
  belongs_to :severe_element
  
end