class Relationship
  include DataMapper::Resource
  property :object1, String, :key => true, :length => 16
  property :type, Enum[:migrated_to, :normalized_to, :include, :unknown]
  property :object2, String, :length => 16

  belongs_to :event
  # the relationship table only describe derivative relationship.  Whole-part relationship is denoted
  # by the has and belongs_to associations.  Describing whole-part relationship using Relationship class
  # is currently restricuted to 1-to-1 derivative relationship.
end

# note: may need relationships among representations, ex. shapefiles may be grouped into 
# a reprensentation, and thus if the shapefiles representation is migrated to another collection 
# of files, a relationship among representation would be needed.
 
