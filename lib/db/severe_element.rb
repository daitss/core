
class SevereElement
  include DataMapper::Resource
  property :id, Serial, :key => true
  property :name, String  # the name of the severe element
  property :class, Discriminator
  
  belongs_to :datafile, :through => Resource
end

class Inhibitor < SevereElement
  property :target, String # the target of this inhibitor
  property :key, String # the key to resolve the inhibitor

  def fromPremis(premis)
    attribute_set(:name, premis.find_first("premis:inhibitorType", NAMESPACES).content)
    attribute_set(:target, premis.find_first("premis:inhibitorTarget", NAMESPACES).content)    
    node = premis.find_first("premis:inhibitorKey", NAMESPACES)
    attribute_set(:key, node.content) unless node.nil?
  end
end

class Anomaly < SevereElement
  def fromPremis(premis)
      attribute_set(:name, premis.content)
  end
end

