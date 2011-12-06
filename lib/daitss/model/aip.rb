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

    # report error upon failure in saving 
    def check_errors
      unless self.valid?
        bigmessage = self.errors.full_messages.join "\n" 
        raise bigmessage unless bigmessage.empty?
      end
      
      unless copy.valid?
        bigmessage =  copy.errors.full_messages.join "\n" 
        raise bigmessage unless bigmessage.empty?
      end
    end
   
    def toDB
      # @datafiles.each {|dfid, df| df.check_errors unless  df.save }
      unless self.save
        self.check_errors 
        raise "error in saving Aip record, no validation error found"
      end
    end
   
    # @return [Boolean] true if Aip instance and associated fast access data were saved
      #Aip.transaction do
       # self.save
      #  AIPInPremis.new.process self.package, LibXML::XML::Document.string(self.xml)
      #end
  end

end
