require 'db/pobject'

class Bitstream < Pobject
  include DataMapper::Resource
  property :id, String, :key => true, :length => 100
  property :size, Integer

  belongs_to :datafile # a bitstream is belong to a datafile
  has 0..n, :object_format # a bitstream may have 0-n file_formats
  has 0..n, :documents
  has 0..n, :texts
  has 0..n, :audios
  has 0..n, :images

  def fromPremis(premis, formats)
    attribute_set(:id, premis.find_first("premis:objectIdentifier/premis:objectIdentifierValue", NAMESPACES).content)

    # process premis ObjectCharacteristicExtension 
    node = premis.find_first("premis:objectCharacteristics/premis:objectCharacteristicsExtension", NAMESPACES)
    if (node)
      processObjectCharacteristicExtension(self, node)
      @object.datafile_id = :null
    end

    # process format information
    processFormats(self, premis, formats)
  end
end
