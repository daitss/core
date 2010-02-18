
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
    entity = premis.find_first('//p2:object[p2:objectCategory="intellectual entity"]', NAMESPACES)
    puts entity
    
    # extract and set int entity id
    id = entity.find_first("//p2:objectIdentifierValue", NAMESPACES) unless entity.nil?
    puts id
    if id
      attribute_set(:id, id.content)
    else
      #TODO: this is only temporary, should be removed once AIP descriptor building is complete
      attribute_set(:id, "E00000000_000000")
    end
    
    # extract and set the rest of int entity metadata
    
  end
  
  def processMods premis
    
  end
  
  def match id
    matched = false
    if id && id == @id
      matched = true
    end
    matched
  end
end