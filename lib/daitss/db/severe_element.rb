module Daitss

  class SevereElement
    include DataMapper::Resource
    property :id, Serial, :key => true
    property :name, String, :length => 255, :index => true  # the name of the severe element
    property :class, Discriminator

    has n, :datafile_severe_element#, :constraint=>:destroy
    # has 1..n, :datafile, :through => :datafile_severe_element, :constraint=>:destroy
    # has 1..n, :datafiles, :through => Resource, :constraint=>:destroy

  end

  class Inhibitor < SevereElement
    property :target, String, :length => 255  # the target of this inhibitor
    property :ikey, String, :length => 255  # the key to resolve the inhibitor

    def fromPremis(premis)
      attribute_set(:name, premis.find_first("premis:inhibitorType", NAMESPACES).content)
      node = premis.find_first("premis:inhibitorTarget", NAMESPACES)
      attribute_set(:target, node.content) unless node.nil?
      node = premis.find_first("premis:inhibitorKey", NAMESPACES)
      attribute_set(:ikey, node.content) unless node.nil?
    end
  end

  # for certain anomaly, JHOVE outputs tons of variation for the same kind of anomaly, e.g.
  #"Value offset not word-aligned : 644", "Value offset not word-aligned : 1250", etc.  This is
  # the set to combine those anomalies into a simplied one.
  # To Do: finish the conversion.
  TRIM_ANOMALY = [
    "Value offset not word-aligned",
    "Unknown TIFF IFD tag",
    "Flash value out of range",
    "Invalid DateTime length",
    "Type mismatch for tag",
    "Invalid DateTime separator",
    "out of sequence"
  ]

  class Anomaly < SevereElement
    def fromPremis(premis)
      # truncate the anomaly name over 255 characters
      truncated = premis.content.slice(0, 255)
      attribute_set(:name, truncated)
    end
  end

end
