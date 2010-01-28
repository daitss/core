class Bitstream
  include DataMapper::Resource
  property :id, String, :key => true, :length => 16
  property :size, Integer

  belongs_to :datafile # a bitstream is belong to a datafile
  has 0..n, :object_format # a bitstream may have 0-n file_formats
  has 0..n, :documents
  has 0..n, :texts
  has 0..n, :audios
  has 0..n, :images
     
  def fromPremis premis
    attribute_set(:id, premis.find_first("premis:objectIdentifier/premis:objectIdentifierValue", NAMESPACES).content)
  end
end
