require 'rubygems'
require 'dm-core'
require 'dm-types'

DataMapper::Logger.new(STDOUT, :debug)
DataMapper.setup(:default, 'mysql://root@localhost/foo')

class Intentity 
  include DataMapper::Resource
  property :id, String, :key => true, :length => 16
  property :original_name, String
  property :entity_id, String
  property :volume, String
  property :issue, String
  property :title, Text
  
  has 0..n, :intentity_events
  has 1..n, :representations
end

class Representation
  include DataMapper::Resource  
  property :id, String, :key => true, :length => 16
  property :name, String
  property :namespace, Enum[:local]

  belongs_to :intentity
    # representation is part of an int entity
  # has 1..n, :datafiles
  has 0..n, :representation_events
end

class Agent
  include DataMapper::Resource
  property :id, String, :key => true
  property :name, String
  property :type, Enum[:software, :person, :organization]
  
  has 0..n, :events # an agent can create 0-n int entity events.
end


class Event
  include DataMapper::Resource
  property :id, String, :key => true, :length => 16
  property :idType, String # identifier type
  property :type, Enum[:submit, :validate, :ingest, :disseminate, 
    :withdraw, :fixitycheck, :describe, :migrate, :normalize]
  property :datetime, DateTime
  property :details, String # additional detail information about the event
  property :outcome, String  # ex. sucess, failed.  TODO:change to Enum.
  property :outcome_details, String  # additional information about the event outcome.
  # property :relatedObjectType, String # the type of the related object, ex. intentity
  # property :relatedObjectID, String # the identifier of the related object.
  # 
  property :class, Discriminator
  belongs_to :agent
   # an event must be associated with an agent
   
end

class IntentityEvent < Event
  belongs_to :intentity
end

class RepresentationEvent < Event
  belongs_to :representation
end

class DatafileEvent < Event; end
  belongs_to, :datafiles
end

DataMapper::auto_migrate!