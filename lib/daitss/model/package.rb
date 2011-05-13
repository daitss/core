require 'data_mapper'

require 'daitss/db'
require 'daitss/model/aip'
require 'daitss/model/eggheadkey'
require 'daitss/model/event'
require 'daitss/model/project'
require 'daitss/model/request'
require 'daitss/model/sip'

module Daitss

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
    has 0..1, :report_delivery

    belongs_to :project
    belongs_to :batch, :required => false

    LEGACY_EVENTS = [
      'legacy operations data',
      'daitss v.1 provenance',
      'migrated from rejects db'
    ]

    FIXITY_PASSED_EVENTS = [
      'fixity success',
      'integrity success'
    ]

    FIXITY_FAILED_EVENTS = [
      'fixity failure',
      'integrity failure'
    ]

    def normal_events
      events.all(:order => [:id.asc]) - (fixity_passed_events + legacy_events + fixity_failed_events)
    end

    def fixity_events
      events.all :name => (FIXITY_PASSED_EVENTS + FIXITY_FAILED_EVENTS), :order => [:id.asc]
    end

    def fixity_passed_events
      events.all :name => FIXITY_PASSED_EVENTS, :order => [:id.asc]
    end

    def fixity_failed_events
      events.all :name => FIXITY_FAILED_EVENTS, :order => [:id.asc]
    end

    def legacy_events
      events.all :name => LEGACY_EVENTS, :order => [:id.asc]
    end

    # add an operations event for abort
    def abort user, note
      event = Event.new :name => 'abort', :package => self, :agent => user, :notes => note
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
      events.first :name => 'reject' or events.first :name => 'daitss v.1 reject'
    end

    def migrated_from_pt?
      events.first :name => "daitss v.1 provenance"
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

    def queue_reject_report
      r = ReportDelivery.new :type => :reject
      (self.project.account.report_email == nil or self.project.account.report_email.length == 0) ? r.mechanism = :ftp : r.mechanism = :email
      r.package = self

      r.save
    end


  end

end
