class Bitstream
  include DataMapper::Resource
  property :id, String, :key => true, :length => 16
  property :size, Integer

  belongs_to :datafile # a bitstream is belong to a datafile
  belongs_to :object_formats # bitstream format
  
  def fromPremis premis
    attribute_set(:id, premis.find_first("premis:objectIdentifier/premis:objectIdentifierValue", NAMESPACES).content)
  end
end
