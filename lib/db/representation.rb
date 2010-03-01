REP_CURRENT = "representation/current"
REP_0 = "representation/original"

class Representation
  include DataMapper::Resource  
  property :id, String, :key => true, :length => 100
  property :name, String
  property :namespace, Enum[:local]

  belongs_to :intentity
  # representation is part of an int entity
  has n, :datafile_representation, :constraint=>:destroy
  has 1..n, :datafiles, :through => :datafile_representation, :constraint=>:destroy
  
  # extract representation properties from a premis document
  def fromPremis premis
    attribute_set(:id, premis.find_first("premis:objectIdentifier/premis:objectIdentifierValue", NAMESPACES).content)
    attribute_set(:namespace, :local)
  end

  # if this representation represents the original representation?
  def isR0
    yes = false
    yes = true if (@id.include? REP_0)
  end
  
  # is this representation represents the current representation?
  def isRC
    yes = false
    yes = true if (@id.include? REP_CURRENT)
  end
  
end
