
class Intentity 
  include DataMapper::Resource
  property :id, String, :key => true, :length => 100
  property :original_name, String
  property :entity_id, String
  property :volume, String
  property :issue, String
  property :title, Text
  
  # belongs_to :project
  # has 0..n, :intentity_events
  has 1..n, :representations
  
  def fromPremis premis
    id = premis.find_first("//p2:intellectualEntity/p2:intellectualEntityIdentifier/p2:intellectualEntityIdentifierValue", NAMESPACES)
    if id
      attribute_set(:id, id.content)
    else
      #TODO: this is only temporary, should be removed once AIP descriptor building is complete
      attribute_set(:id, "E00000000_000000")
    end
  end
  
  def match id
    matched = false
    if id && id == @id
      matched = true
    end
    matched
  end
end