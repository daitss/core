class Request
  include DataMapper::Resource
  property :id, Serial, :key => true
  property :note, Text

  property :timestamp, DateTime, :required => true, :default => proc { DateTime.now }
  property :is_authorized, Boolean, :required => true, :default => true
  property :status, Enum[:enqueued, :released_to_workspace, :cancelled], :default => :enqueued
  property :type, Enum[:ingest, :disseminate, :withdraw, :peek, :d1refresh, :sleep]

  # TODO investigate Wip::VALID_TASKS - [:sleep, :ingeset] to have one place for it all

  belongs_to :agent
  belongs_to :package

  def cancel
    self.status = :cancelled
    self.save
  end

  include DataDir

  # create a wip from this request
  def dispatch

    begin

      # make a wip
      dp_path = File.join dispatch_path, package.id
      ws_path = File.join work_path, package.id
      Wip.create dp_path, type
      FileUtils.mv dp_path, ws_path

      # save and log
      Request.transaction do
        self.status = :released_to_workspace
        self.save or raise "cannot save request"
        package.log "#{type} released", :notes => "request_id: #{id}"
      end

    rescue

      # cleanup wip on fs
      FileUtils.rm_r dp_path if File.exist? dp_path
      FileUtils.rm_r ws_path if File.exist? ws_path

      # re-raise
      raise
    end

  end

end
