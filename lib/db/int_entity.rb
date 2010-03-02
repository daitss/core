
class Intentity 
  include DataMapper::Resource
  property :id, String, :key => true, :length => 100
  # daitss1 ieid
  property :original_name, String # i.e. package_name
  property :entity_id, String
  property :volume, String
  property :issue, String
  property :title, Text
  
  # belongs_to :project
  has 1..n, :representations, :constraint=>:destroy
  
  before :destroy, :deleteChildren
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
  
  # delete this datafile record and all its children from the database
  def deleteChildren
    puts "DELETE #{self.inspect}"
    # delete all events associated with this int entity
    dfevents = Event.all(:relatedObjectId => @id)
    dfevents.each do |e|
      # delete all relationships associated with this event
      rels = Relationship.all(:event_id => e.id)
      rels.each {|rel| rel.destroy!}
      puts e.inspect
      e.destroy!
    end
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