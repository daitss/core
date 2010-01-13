$:.unshift File.join(File.dirname(__FILE__), 'lib')

# aip.rb
require 'rubygems'
require 'xml'
require 'lib/namespaces.rb'
require 'lib/AIPInPremis.rb'

class AIP
  # curl -F "data=@files/descriptor.xml" http://localhost:4567/aip2db
 
  def process aip_file
    # read in the posted AIP descriptor
  
    doc = XML::Document.io aip_file
    aip = AIPInPremis.new
    
    fileObjects = doc.find("//premis:object[@xsi:type='file']", NAMESPACES)
    fileObjects.each do |obj|
      aip.processDatafile obj
    end
    
    repObjects = doc.find("//premis:object[@xsi:type='representation']", NAMESPACES)
    repObjects.each do |obj|
      aip.processRepresentation obj    
    end
         
    agentObjects = doc.find("//premis:agent", NAMESPACES)
    agentObjects.each do |obj|
      aip.processAgent obj
    end
    
    eventObjects = doc.find("//premis:event", NAMESPACES)
    eventObjects.each do |obj|
      aip.processEvent obj
    end
    
    aip.toDB
  end

end 
