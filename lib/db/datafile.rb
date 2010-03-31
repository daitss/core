require 'db/pobject'

class Datafile < Pobject
  include DataMapper::Resource 
  property :id, String, :key => true, :length => 100
  property :size, Integer, :length => (0..20),  :required => true 
  property :create_date, DateTime
  property :origin, Enum[:archive, :depositor, :unknown], :default => :unknown, :required => true 
  property :original_path, String, :length => (0..255), :required => true 
    # map from package_path + file_title + file_ext
  property :creating_application, String, :length => (0..255)
   
  has 0..n, :bitstreams, :constraint=>:destroy # a datafile may contain 0-n bitstream(s)
  has n, :datafile_severe_element, :constraint=>:destroy
  #  has 0..n, :severe_element, :through => :datafile_severe_element, :constraint=>:destroy # a datafile may contain 0-n severe_elements
  #has 0..n, :severe_elements, :through => Resource, :constraint=>:destroy # a datafile may contain 0-n severe_elements
  has 0..n, :documents, :constraint => :destroy 
  has 0..n, :texts, :constraint => :destroy 
  has 0..n, :audios, :constraint => :destroy 
  has 0..n, :images, :constraint => :destroy 
  has 0..n, :message_digest, :constraint => :destroy 
  
  has n, :object_format, :constraint=>:destroy # a datafile may have 0-n file_formats
  has 0..n, :broken_links, :constraint=>:destroy # if there is missing links in the datafiles (only applies to xml)

  has n, :datafile_representation, :constraint=>:destroy
#  has 1..n, :representations, :through => :datafile_representation #, :constraint=>:destroy
#  has 1..n, :representations, :through => Resource, :constraint=>:destroy
  
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
    if premis.find_first("premis:objectCharacteristics/premis:fixity", NAMESPACES)
      messageDigest = MessageDigest.new
      messageDigest.fromPremis(premis)
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
  
  # derive the datafile origin by its association to representations r0, rc
  def setOrigin(r0, rc, rn)
    # if this datafile is in r(c) or r(n) but not in r(0), it is created by the archive, otherwise it is submitted by depositor.
    if ( (rc.include?(@id) || rn.include?(@id)) && !r0.include?(@id) )
      attribute_set(:origin, :archive)
    else
      attribute_set(:origin, :depositor)
    end
  end
  
  # delete this datafile record and all its children from the database
  def deleteChildren
    puts "delete datafiles #{self.inspect}"
    # delete all events associated with this datafile
    dfevents = Event.all(:relatedObjectId => @id)
    dfevents.each do |e|
      # delete all relationships associated with this event
      rels = Relationship.all(:event_id => e.id)
      rels.each {|rel| raise "error deleting relationship #{rel.inspect}" unless rel.destroy}
      puts e.inspect
      raise "error deleting event #{e.inspect}" unless e.destroy
    end
    
  end
  
end