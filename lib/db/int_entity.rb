
class Intentity 
  include DataMapper::Resource
  property :id, String, :key => true, :length => 16
  property :original_name, String
  property :entity_id, String
  property :volume, String
  property :issue, String
  property :title, Text
  
  # belongs_to :project
  # has 0..n, :intentity_events
  has 1..n, :representations
  
  def fromPremis
    # TODO: implement
    attribute_set(:id, "E00000000_000000")
  end
end