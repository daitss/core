$:.unshift File.join(File.dirname(__FILE__), 'lib')

# aip2db.rb
require 'rubygems'
require 'sinatra'
require 'xml'
require 'lib/namespaces.rb'
require 'lib/FileObject.rb'

class AIP2DB < Sinatra::Base
  enable :logging 
  set :root, File.dirname(__FILE__)

  error do
    'Encounter Error ' + env['sinatra.error'].name
  end

  # curl -F "data=@file/monodescriptor.xml" http://localhost:4567/aip2db
  post '/aip2db' do
    puts "post"

    # read in the posted AIP descriptor
    puts params[:data][:tempfile]
    XML.default_keep_blanks = false
    doc = XML::Document.io params[:data][:tempfile]
    fileObjects = doc.find("//premis:object[@type='file']", NAMESPACES)
    fileObjects.each do |obj|
      fileobj = FileObject.new
      fileobj.fromPremis obj
      fileobj.toDB
    end
  end

end 

AIP2DB.run! if __FILE__ == $0