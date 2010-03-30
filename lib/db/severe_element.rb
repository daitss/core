
class SevereElement
  include DataMapper::Resource
  property :id, Serial, :key => true
  property :name, String  # the name of the severe element
  property :class, Discriminator
  
  has n, :datafile_severe_element#, :constraint=>:destroy
  # has 1..n, :datafile, :through => :datafile_severe_element, :constraint=>:destroy
  # has 1..n, :datafiles, :through => Resource, :constraint=>:destroy
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

