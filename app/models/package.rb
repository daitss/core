class Package
  include DataMapper::Resource

  property :id, EggHeadKey
  property :uri, String, :unique => true, :required => true, :default => proc { |r,p| Setting.get('uri prefix').value + r.id }

  has n, :events
  has n, :requests
  has 1, :sip
  has 0..1, :aip
  #has 0..1, :intentity
  has 0..1, :report_delivery

  belongs_to :project

  has n, :listings
  has n, :lists, :through => :listings

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
    e.timestamp = options[:timestamp] if options[:timestamp]

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

  def stashed_wip
    bins = Daitss.archive.stashspace
    bin = bins.find { |b| File.exist? File.join(b.path, id) }
    bin.find { |w| w.id == id } if bin
  end

  def rejected?
    events.first :name => 'reject'
  end

  def migrated_from_pt?
    events.first :name => "migrated from package tracker"
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

  def elapsed_time
    raise "package not yet ingested" unless status == 'archived'
    return 0 if self.id =~ /^E20(05|06|07|08|09|10|11)/ #return 0 for D1 pacakges

      event_list = self.events.all(:name => "ingest started") + self.events.all(:name => "ingest snafu") + self.events.all(:name => "ingest stopped") + self.events.first(:name => "ingest finished")

    event_list.sort {|a, b| a.timestamp <=> b.timestamp}

    elapsed = 0
    while event_list.length >= 2
      elapsed += Time.parse(event_list.pop.timestamp.to_s) - Time.parse(event_list.pop.timestamp.to_s)
    end

    return elapsed
  end

  def d1?

    if aip.xml
      doc = Nokogiri::XML aip.xml
      doc.root.name == 'daitss1'
    end

  end

  def dips

    Dir.chdir archive.disseminate_path do
      Dir['*'].select { |dip| dip =~ /^#{id}-\d+.tar$/ }
    end

  end

end

# a list of packages
class List
  include DataMapper::Resource
  property :id, String, :key => true
  has n, :listings
  has n, :packages, :through => :listings
end

# association between a package and list
class Listing
  include DataMapper::Resource
  belongs_to :list, :key => true
  belongs_to :package, :key => true
end
