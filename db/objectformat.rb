class ObjectFormat
  include DataMapper::Resource
  property :id, Serial, :key => true
  property :type, Enum[:primary, :secondary], :default => :primary # indicate if this format is perceived to be 
    # the primary or secondary format for this data file
  
  belongs_to :format, :index => true # the format of the datafile or bitstream. 
  belongs_to :datafile, :index => true # The data file which may exibit the specific format
  belongs_to :bitstream, :index => true # The data file which may exibit the specific format
  
  def setPrimary
    attribute_set(:type, :primary)
  end
  
  def setSecondary
    attribute_set(:type, :secondary)
  end
     
end