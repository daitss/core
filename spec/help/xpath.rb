module Premis
  
  def object type, value
    "premis:object[premis:objectIdentifier[premis:objectIdentifierType = '#{type}' and premis:objectIdentifierValue = '#{value}']]"
  end
  
  module_function :object
  
end
