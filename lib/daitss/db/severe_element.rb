module Daitss

  class SevereElement
    include DataMapper::Resource
    property :id, Serial, :key => true
    property :name, String, :length => 255  # the name of the severe element
    property :class, Discriminator

    has n, :datafile_severe_element#, :constraint=>:destroy
    # has 1..n, :datafile, :through => :datafile_severe_element, :constraint=>:destroy
    # has 1..n, :datafiles, :through => Resource, :constraint=>:destroy

    before :save do
      puts self.inspect
      puts "#{self.errors.to_a} error encountered while saving #{self.inspect} " unless valid?
    end
  end

  class Inhibitor < SevereElement
    property :target, String # the target of this inhibitor
    property :ikey, String # the key to resolve the inhibitor

    def fromPremis(premis)
      attribute_set(:name, premis.find_first("premis:inhibitorType", NAMESPACES).content)
      node = premis.find_first("premis:inhibitorTarget", NAMESPACES)
      attribute_set(:target, node.content) unless node.nil?
      node = premis.find_first("premis:inhibitorKey", NAMESPACES)
      attribute_set(:ikey, node.content) unless node.nil?
    end
  end

  class Anomaly < SevereElement
    def fromPremis(premis)
      attribute_set(:name, premis.content)
    end
  end

end
