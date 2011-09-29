require "data_mapper"

require 'libxml'
require 'net/http'
require 'daitss/proc/xmlvalidation'
require 'daitss/archive'
require 'daitss/model/copy'
require 'daitss/db/AIPInPremis'

include LibXML
XML.default_line_numbers = true

module Daitss

  class Aip
    include DataMapper::Resource

    XML_SIZE = 2**32-1

    property :id, Serial
    property :xml, Text, :required => true, :length => XML_SIZE
    property :xml_errata, Text, :required => false
    property :datafile_count, Integer # uncomment after all d1 packages are migrated, :required => true

    belongs_to :package
    has 0..1, :copy # 0 if package has been withdrawn, otherwise, 1

    # @return [Boolean] true if Aip instance and associated fast access data were saved
      #Aip.transaction do
       # self.save
      #  AIPInPremis.new.process self.package, LibXML::XML::Document.string(self.xml)
      #end
  end

end
