require 'libxml'
#require 'daitss/db/AIPInPremis'

class Aip
  include DataMapper::Resource

  XML_SIZE = 2**32-1

  property :id, Serial
  property :xml, Text, :required => true, :length => XML_SIZE
  property :xml_errata, Text, :required => false
  property :datafile_count, Integer, :min => 1 # uncomment after all d1 packages are migrated, :required => true

  belongs_to :package
  has 0..1, :copy # 0 if package has been withdrawn, otherwise, 1

  # @return [Boolean] true if Aip instance and associated fast access data were saved
  def save_and_populate
    self.raise_on_save_failure = true

    Aip.transaction do
      self.save
      XML.default_line_numbers = true
      AIPInPremis.new.process self.package, LibXML::XML::Document.string(self.xml)
    end

  end

end
