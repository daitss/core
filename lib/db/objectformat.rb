# define arrays used for validating controlled vocabularies 
PRIMARY = "primary"
SECONDARY = "secondary"
Object_Type = [PRIMARY, SECONDARY]

class ObjectFormat
  include DataMapper::Resource
  property :id, Serial, :key => true
  property :type, String, :length => 10, :required => true # :default => :primary # indicate if this format is perceived to be 
    # the primary or secondary format for this data file
  property :datafile_id, String, :length => 100
  property :bitstream_id, String, :length => 100
  property :note, String, :length => 50

  belongs_to :format, :index => true # the format of the datafile or bitstream. 
  # belongs_to :datafile, :index => true, :default => :null # The data file which may exibit the specific format
  # belongs_to :bitstream, :index => true, :default => :null # The data file which may exibit the specific format
  
  def setPrimary
    attribute_set(:type, PRIMARY)
  end
  
  def setSecondary
    attribute_set(:type, SECONDARY)
  end
     
  after :save do
    puts "#{self.errors.to_a} error encountered while saving #{self.inspect} " unless valid?
	puts format.valid?
	format.errors.to_a
  end
end