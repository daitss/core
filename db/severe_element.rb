
class SevereElement
  include DataMapper::Resource
  property :id, Serial, :key => true
  property :name, String  # the name of the severe element
  property :type, Enum[:inhibitor, :anomaly] # severe element type
  
  belongs_to :datafile
end
