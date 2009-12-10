require "dm-core"

require 'libxml'
require 'schematron'

include LibXML

# authoritative aip record
class Aip
  include DataMapper::Resource
  property :name, String, :key => true
  property :xml, Text, :nullable => false
  property :url, String, :nullable => false
  property :sha1, String, :length => 40, :format => %r([a-f0-9]{40}), :nullable => false
  property :size, Integer, :min => 1, :nullable => false
  property :needs_work, Boolean, :nullable => false
  
  validates_with_block do
    doc = XML::Document.string xml

    # validate against schematron
    results = Aip::SCHEMATRON.validate doc

    unless results.empty?
      [false, "descriptor fails daitss aip schematron validation (#{results.size} errors)"]
    else
      true
    end

  end

end
