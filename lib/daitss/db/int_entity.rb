require 'daitss/model/request'
require 'daitss/db'

class Intentity
  include DataMapper::Resource
  property :id, String, :key => true, :length => 50
    # daitss1 ieid
  property :original_name, String, :length => 32, :required => true, :default => "UNKNOWN"
    # i.e. package_name
  property :entity_id, String, :length => 100
  property :volume, String, :length => 16
  property :issue, String, :length => 16
  property :title, Text

  belongs_to :package
  has 1..n, :datafiles, :constraint=>:destroy

  before :destroy, :deleteChildren

  # construct an int entity with the information from the aip descriptor
  def fromAIP aip
    entity = aip.find_first('//p2:object[p2:objectCategory="intellectual entity"]', NAMESPACES)
    raise "cannot find required intellectual entity object in the aip descriptor" if entity.nil?

    # extract and set int entity id
    id = entity.find_first("//p2:objectIdentifierValue", NAMESPACES)
    raise "cannot find required objectIdentifierValue for the intellectual entity object in the aip descriptor" if id.nil?
    attribute_set(:id, id.content)

    originalName = entity.find_first("//p2:originalName", NAMESPACES)
    attribute_set(:original_name, originalName.content) if originalName

    # extract and set the rest of int entity metadata
    mods = aip.find_first('//mods:mods', NAMESPACES)
    if mods
      title = mods.find_first("mods:titleInfo/mods:title", NAMESPACES)
      attribute_set(:title, title.content) if title
      volume = mods.find_first("mods:part/mods:detail[@type = 'volume']/mods:number", NAMESPACES)
      attribute_set(:volume, volume.content) if volume
      issue = mods.find_first("mods:part/mods:detail[@type = 'issue']/mods:number", NAMESPACES)
      attribute_set(:issue, issue.content) if issue
      entityid = mods.find_first("mods:identifier[@type = 'entity id']", NAMESPACES)
      attribute_set(:entity_id, entityid.content) if entityid
    end
  end

  # delete this datafile record and all its children from the database
  def deleteChildren
    # delete all events associated with this int entity
    dfevents = PremisEvent.all(:relatedObjectId => @id)
    dfevents.each do |e|
      # delete all relationships associated with this event
      rels = Relationship.all(:premis_event_id => e.id)
      rels.each {|rel| rel.destroy}
      e.destroy
    end
  end

  def match id
    matched = false
    if id && id == @id
      matched = true
    end
    matched
  end

 after :save do
    puts "#{self.errors.to_a} error encountered while saving #{self.inspect} " unless valid?
  end
end
