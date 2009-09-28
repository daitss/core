require 'xml'
require 'db/daitss2.rb'

class FileObject
  
  def fromPremis premis
    @id = premis.find_first("premis:objectIdentifier/premis:objectIdentifierValue", NAMESPACES).content
    @size = premis.find_first("premis:objectCharacteristics/premis:size").content
    #TODO format...how to record format profiles?
    
    
  end
end