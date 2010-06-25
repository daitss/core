require 'db/pobject'

# constant for representation id
REP_CURRENT = "representation/current"
REP_0 = "representation/original"
REP_NORM = "representation/normalized"

# constant for datafile origin
ORIGIN_ARCHIVE = "ARCHIVE"
ORIGIN_DEPOSITOR = "DEPOSITOR"
ORIGIN_UNKNOWN = "UNKNOWN"
Origin = [ ORIGIN_ARCHIVE, ORIGIN_DEPOSITOR, ORIGIN_UNKNOWN ]

class Datafile < Pobject
  include DataMapper::Resource

  property :id, String, :key => true, :length => 100
  property :size, Integer, :min => 0,  :required => true
  property :create_date, DateTime
  property :origin, String, :length => 10, :required => true # :default => ORIGIN_UNKNOWN,
    # the value of the origin is validated by the check_origin method
  validates_with_method :origin, :method => :validateOrigin

  property :original_path, String, :length => (0..255), :required => true
  # map from package_path + file_title + file_ext
  property :creating_application, String, :length => (0..255)

  property :r0, String, :index => true, :length => 100
  # contains the id of the original representation if this datafile is part of it
  property :rn, String, :index => true, :length => 100
  # contains the id of the representation norm if this datafile is part of it
  property :rc, String, :index => true, :length => 100
  # contains the id of the representation current if this datafile is part of it
  belongs_to :intentity

  has 0..n, :bitstreams, :constraint=>:destroy # a datafile may contain 0-n bitstream(s)
  has n, :datafile_severe_element, :constraint=>:destroy
  has 0..n, :documents, :constraint => :destroy
  has 0..n, :texts, :constraint => :destroy
  has 0..n, :audios, :constraint => :destroy
  has 0..n, :images, :constraint => :destroy
  has 0..n, :message_digest, :constraint => :destroy
  has n, :object_format, :constraint=>:destroy # a datafile may have 0-n file_formats
  has 0..n, :broken_links, :constraint=>:destroy # if there is missing links in the datafiles (only applies to xml)

  before :destroy, :deleteChildren

  def fromPremis(premis, formats)
    attribute_set(:id, premis.find_first("premis:objectIdentifier/premis:objectIdentifierValue", NAMESPACES).content)
    attribute_set(:size, premis.find_first("premis:objectCharacteristics/premis:size", NAMESPACES).content)

    # creating app. info
    node = premis.find_first("premis:objectCharacteristics/premis:creatingApplication/premis:creatingApplicationName", NAMESPACES)
    attribute_set(:creating_application, node.content) if node

    node = premis.find_first("premis:objectCharacteristics/premis:creatingApplication/premis:dateCreatedByApplication", NAMESPACES)
    attribute_set(:create_date, node.content) if node

    node = premis.find_first("premis:originalName", NAMESPACES)
    attribute_set(:original_path, node.content) if node

    # process format information
    processFormats(self, premis, formats)

    # process fixity information
	fixities = premis.find("premis:objectCharacteristics/premis:fixity", NAMESPACES)
    fixities.each do |fixity|
      messageDigest = MessageDigest.new
      messageDigest.fromPremis(fixity)
      self.message_digest << messageDigest
    end

    # process premis ObjectCharacteristicExtension
    node = premis.find_first("premis:objectCharacteristics/premis:objectCharacteristicsExtension", NAMESPACES)
    if (node)
      processObjectCharacteristicExtension(self, node)
      @object.bitstream_id = :null
    end

    # process inhibitor if there is any
    node = premis.find_first("premis:objectCharacteristics/premis:inhibitors", NAMESPACES)
    if (node)
      inhibitor = Inhibitor.new
      inhibitor.fromPremis(node)
      # use the existing inhibitor record in the database if we have seen this inhibitor before
      existingInhibitor = Inhibitor.first(:name => inhibitor.name)

      dfse = DatafileSevereElement.new
      self.datafile_severe_element << dfse
      if existingInhibitor
        existingInhibitor.datafile_severe_element << dfse
      else
        inhibitor.datafile_severe_element << dfse
      end
    end

  end

  # validate the datafile Origin value which is a daitss defined controlled vocabulary
  def validateOrigin
      if Origin.include?(@origin)
        return true
      else
        [ false, "value #{@origin} is not a valid origin value" ]
      end
    end

  # derive the datafile origin by its association to representations r0, rc
  def setOrigin
    # if this datafile is in r(c) or r(n) but not in r(0), it is created by the archive, otherwise it is submitted by depositor.
    if (( @rc || @rn) && !@r0)
      attribute_set(:origin, ORIGIN_ARCHIVE)
    else
      attribute_set(:origin, ORIGIN_DEPOSITOR)
    end
  end

  # set the representation (r0, rn, rc) which contains this datafile
  def setRepresentations(rep_id)
    if (rep_id.include? REP_0)
      attribute_set(:r0, rep_id)
    elsif  (rep_id.include? REP_CURRENT)
      attribute_set(:rc, rep_id)
    elsif (rep_id.include? REP_NORM)
      attribute_set(:rn, rep_id)
    end
  end

  # delete this datafile record and all its children from the database
  def deleteChildren
    # delete all events associated with this datafile
    dfevents = Event.all(:relatedObjectId => @id)
    dfevents.each do |e|
      # delete all relationships associated with this event
      rels = Relationship.all(:event_id => e.id)
      rels.each {|rel| raise "error deleting relationship #{rel.inspect}" unless rel.destroy}
      raise "error deleting event #{e.inspect}" unless e.destroy
    end
  end

  after :save do
    puts "#{self.errors.to_a} error encountered while saving #{self.inspect} " unless valid?
    puts "saving datafile #{self.inspect}"
	puts bitstreams.map &:valid?
	bitstreams.each {|b| puts b.errors.to_a }
	puts texts.map &:valid?
	texts.each {|b| puts b.errors.to_a }
	puts audios.map &:valid?
	audios.each {|b| puts b.errors.to_a }	
	puts images.map &:valid?
    images.each {|b| puts b.errors.to_a }	
	puts documents.map &:valid?
	documents.each {|b| puts b.errors.to_a }
	puts "message digest"
	puts message_digest.map &:valid?
    message_digest.each {|b| puts b.errors.to_a }
	puts "datafile_severe_element"
	puts datafile_severe_element.map &:save
	puts datafile_severe_element.map &:valid?
    datafile_severe_element.each {|b| puts b.errors.to_a }
	puts "object_format"
	puts object_format.save
	puts object_format.map &:valid?
	puts "broken_link"
	puts broken_links.map &:valid?
    broken_links.each {|b| puts b.errors.to_a }
  end
end
