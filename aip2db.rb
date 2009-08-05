$:.unshift File.join(File.dirname(__FILE__), 'lib')

# aip2db.rb
require 'rubygems'
require 'sinatra'
require 'xml'

NAMESPACES = {
  'mets' => 'http://www.loc.gov/METS/',
  'xsi' => 'http://www.w3.org/2001/XMLSchema-instance',
  'premis' => 'info:lc/xmlns/premis-v2',
  'mix' => 'http://www.loc.gov/mix/v20',
  'aes' => 'http://www.aes.org/audioObject'
}

class AIP2DB < Sinatra::Base
  enable :logging 
  set :root, File.dirname(__FILE__)

  error do
    'Encounter Error ' + env['sinatra.error'].name
  end

  # curl -F "data=@descriptor1.xml" http://localhost:4567/aip2db
  post '/aip2db' do
    puts "post"

    # read in the posted AIP descriptor
    puts params[:data][:tempfile]
    XML.default_keep_blanks = false
    doc = XML::Document.io params[:data][:tempfile]
    
    files = doc.find("//premis:object[@type='file']", NAMESPACES)
    puts files
    files.each do |obj|
      puts obj
    end
  end

end 

AIP2DB.run! if __FILE__ == $0