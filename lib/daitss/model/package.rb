require 'data_mapper'

require 'daitss/db'
require 'daitss/model/aip'
require 'daitss/model/eggheadkey'
require 'daitss/model/event'

# authoritative package record
class Package
  include DataMapper::Resource

  property :id, EggHeadKey

  has n, :events
  has n, :requests
  has 1, :sip
  has 0..1, :aip
  has 0..1, :intentity

  belongs_to :project, :required => false

  # add an operations event for abort
  def abort user
    event = Event.new :name => 'abort', sip => self, :agent => user
    event.save or raise "cannot save op event"
  end

  # make an event for this package
  def log name, options={}
    e = Event.new :name => name, :package => self
    e.agent = options[:agent] || Program.system_agent
    e.notes = options[:notes]
    e.save or raise "cannot save op event: #{name}"
  end

end
