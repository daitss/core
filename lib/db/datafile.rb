require 'db/pobject'

class Datafile < Pobject
  include DataMapper::Resource 
  property :id, String, :key => true, :length => 16
  property :size, Integer, :length => (0..20),  :required => true 
  property :create_date, DateTime
  property :origin, Enum[:archive, :depositor, :unknown], :default => :unknown, :required => true 
  property :original_path, String, :length => (0..255), :required => true 
    # map from package_path + file_title + file_ext
  property :creator_prog, String, :length => (0..255)

  has 1..n, :representations, :through => Resource
  has 0..n, :bitstreams # a datafile may contain 0-n bitstream(s)
  has 0..n, :severe_element # a datafile may contain 0-n severe_elements
  has 0..n, :object_format # a datafile may have 0-n file_formats
  has 0..n, :documents
  has 0..n, :texts
  has 0..n, :audios
  has 0..n, :images
  
  def fromPremis(premis, formats)
    attribute_set(:id, premis.find_first("premis:objectIdentifier/premis:objectIdentifierValue", NAMESPACES).content)
    attribute_set(:size, premis.find_first("premis:objectCharacteristics/premis:size", NAMESPACES).content)

    # creating app. info
    node = premis.find_first("premis:objectCharacteristics/premis:creatingApplication/premis:creatingApplicationName", NAMESPACES)
    attribute_set(:creator_prog, node.content) if node
    
    node = premis.find_first("premis:objectCharacteristics/premis:creatingApplication/premis:dateCreatedByApplication", NAMESPACES)
    attribute_set(:create_date, node.content) if node
    
    node = premis.find_first("premis:originalName", NAMESPACES)
    attribute_set(:original_path, node.content) if node
    
    # TODO need to set the origin
    
    # process premis ObjectCharacteristicExtension 
    node = premis.find_first("premis:objectCharacteristics/premis:objectCharacteristicsExtension", NAMESPACES)
    if (node)
      processObjectCharacteristicExtension(self, node)
      @object.bitstream_id = :null
    end
    
    # process format information
    processFormats(self, premis, formats)
  end
  
end