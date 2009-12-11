class Representation
  include DataMapper::Resource  
  property :id, String, :key => true, :length => 50
  property :name, String
  property :namespace, Enum[:local]

  belongs_to :intentity
    # representation is part of an int entity
  has 1..n, :datafiles, :through => Resource
  # has 0..n, :representation_events
  
  def fromPremis premis
    attribute_set(:id, premis.find_first("premis:objectIdentifier/premis:objectIdentifierValue", NAMESPACES).content)
    attribute_set(:namespace, :local)
  end
  
end
