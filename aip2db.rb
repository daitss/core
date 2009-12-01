$:.unshift File.join(File.dirname(__FILE__), 'lib')

# aip2db.rb
require 'rubygems'
require 'sinatra'
require 'xml'
require 'lib/namespaces.rb'
require 'lib/AIPInPremis.rb'

class AIP2DB < Sinatra::Base
  enable :logging 
  set :root, File.dirname(__FILE__)

  error do
    'Encounter Error ' + env['sinatra.error'].name
  end

  # curl -F "data=@files/descriptor.xml" http://localhost:4567/aip2db
  post '/aip2db' do
    # read in the posted AIP descriptor
    puts params[:data][:tempfile]
    XML.default_keep_blanks = false
    doc = XML::Document.io params[:data][:tempfile]
    aip = AIPInPremis.new
    
    fileObjects = doc.find("//premis:object[@xsi:type='file']", NAMESPACES)
    fileObjects.each do |obj|
      aip.processDatafile obj
    end
    
    repObjects = doc.find("//premis:object[@xsi:type='representation']", NAMESPACES)
    repObjects.each do |obj|
      aip.processRepresentation obj    
    end
    
    eventObjects = doc.find("//premis:event", NAMESPACES)
    eventObjects.each do |obj|
      aip.processEvent obj
    end
     
    aip.toDB
  end

end 

AIP2DB.run! if __FILE__ == $0