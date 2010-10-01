module Daitss

  DEFAULT_REGISTRY = "http://www.fda.fcla.edu/format"

  class Format
    include DataMapper::Resource
    property :id, Serial, :key => true
    property :registry, String # the namespace of the format registry, ex:http://www.nationalarchives.gov.uk/pronom
    property :registry_id, String # the format identifier in the registry, ex: fmt/10
    property :format_name, String, :length => 255 # common format name, ex:  "TIFF"
    property :format_version, String #format version,  ex: "5.0"

    has 0..n, :object_format

    def fromPremis premis
      attribute_set(:format_name, premis.find_first("premis:formatDesignation/premis:formatName", NAMESPACES).content)
      if premis.find_first("premis:formatDesignation/premis:formatVersion", NAMESPACES)
        attribute_set(:format_version, premis.find_first("premis:formatDesignation/premis:formatVersion", NAMESPACES).content)
      end

      if premis.find_first("premis:formatRegistry", NAMESPACES)
        attribute_set(:registry, premis.find_first("premis:formatRegistry/premis:formatRegistryName", NAMESPACES).content)
        attribute_set(:registry_id, premis.find_first("premis:formatRegistry/premis:formatRegistryKey", NAMESPACES).content)
      end
    end

    after :save do
      puts "#{self.errors.to_a} error encountered while saving #{self.inspect} " unless valid?
    end

  end

end
