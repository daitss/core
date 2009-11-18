require 'xml'
require 'db/daitss2.rb'

class FormatObject

  def exist?
    format = Format.first(:fornatm_name => @formatName)
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