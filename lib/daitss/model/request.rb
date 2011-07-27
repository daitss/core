require 'data_mapper'

require 'daitss/model/agent'
require 'daitss/model/package'
require 'daitss/proc/wip'
require 'daitss/archive'

module Daitss

  class Request
    include DataMapper::Resource
    property :id, Serial, :key => true
    property :note, Text

    property :timestamp, DateTime, :required => true, :default => proc { DateTime.now }
    property :is_authorized, Boolean, :required => true, :default => true
    property :status, Enum[:enqueued, :released_to_workspace, :cancelled], :default => :enqueued
    property :type, Enum[:disseminate, :withdraw, :peek, :d1refresh]

    # TODO investigate Wip::VALID_TASKS - [:sleep, :ingeset] to have one place for it all

    belongs_to :agent
    belongs_to :package

    def cancel
      self.status = :cancelled
      self.save
    end

    # create a wip from this request
    def dispatch

      begin

        # if d1refresh, check package history to see if already d1refreshed, if so, don't make wip
        if self.type == :d1refresh and Event.first(:name => "d1refresh finished", :package_id => self.package.id)
          return nil
        end

        # make a wip
        dp_path = File.join archive.dispatch_path, package.id
        ws_path = File.join archive.workspace.path, package.id
        Wip.make dp_path, type
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


end
