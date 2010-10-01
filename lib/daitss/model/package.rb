require 'data_mapper'

require 'daitss/db'
require 'daitss/model/aip'
require 'daitss/model/eggheadkey'
require 'daitss/model/event'

# authoritative package record
class Package
  include DataMapper::Resource

  property :id, EggHeadKey
  property :uri, String, :unique => true, :required => true, :default => proc { |r,p| Daitss.archive.uri_prefix + r.id }

  has n, :events
  has n, :requests
  has 1, :sip
  has 0..1, :aip
  has 0..1, :intentity

  belongs_to :project

  # add an operations event for abort
  def abort user
    event = Event.new :name => 'abort', :package => self, :agent => user
    event.save or raise "cannot save abort event"
  end

  # make an event for this package
  def log name, options={}
    e = Event.new :name => name, :package => self
    e.agent = options[:agent] || Program.get("SYSTEM")
    e.notes = options[:notes]

    unless e.save
      raise "cannot save op event: #{name} (#{e.errors.size}):\n#{e.errors.map.join "\n"}"
    end

  end

  # return a wip if exists in workspace, otherwise nil
  def wip
    ws_wip = Daitss.archive.workspace[id]

    if ws_wip
      ws_wip
    else
      bins = Daitss.archive.stashspace
      bin = bins.find { |b| File.exist? File.join(b.path, id) }
      bin.find { |w| w.id == id } if bin
    end

  end

  def rejected?
    events.first :name => 'reject'
  end

  def status

    if self.aip
      'archived'
    elsif self.events.first :name => 'reject'
      'rejected'
    elsif self.wip
      'ingesting'
    elsif self.stashed_wip
      'stashed'
    else
      'submitted'
    end

  end

end
