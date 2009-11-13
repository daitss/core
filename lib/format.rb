require 'xml'
require 'db/daitss2.rb'

class Format

  def exist?
    format = Format.first(:fornatm_name => @formatName)
  end

  def fromPremis premis
    @formatName = node.find_first("premis:formatDesignation/premis:formatName", NAMESPACES).content
    if node.find_first("premis:formatDesignation/premis:formatVersion", NAMESPACES)
      @formatVersion = node.find_first("premis:formatDesignation/premis:formatVersion", NAMESPACES).content
    end

    if node.find_first("premis:formatRegistry", NAMESPACES)
      @registry = node.find_first("premis:formatRegistry/premis:formatRegistryName", NAMESPACES).content
      @registry_id node.find_first("premis:formatRegistry/premis:formatRegistryKey", NAMESPACES).content
    end
  end

  def toDB
    format = Format.new
    format.registry = @registry
    df.registry_id = @registry_id
    df.format_name = @formatName
    df.format_version = @formatVersion

    df.save 
  end
  
end