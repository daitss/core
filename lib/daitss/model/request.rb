require 'data_mapper'
require 'dm-is-list'

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
    property :is_authorized, Boolean, :required => true, :default => false
    property :status, Enum[:enqueued, :released_to_workspace, :cancelled], :default => :enqueued
    property :type, Enum[:disseminate, :withdraw, :peek, :migration]

    belongs_to :agent
    belongs_to :package

    is :list, :scope => [:package_id]

    def cancel
      self.status = :cancelled
      self.save
    end

    def dispatch
      ws_path = archive.workspace.path
      path = File.join(ws_path, self.package.id)
      wip = Wip.new path

      case type

      when :disseminate
        wip.tags["drop-path"] = "/tmp/disseminations"
        wip.tags["dissemination-request"] = Time.now.to_s
      when :withdraw
        wip.tags["withdrawal-request"] = Time.now.to_s
      when :peek
        wip.tags["peek-request"] = Time.now.to_s
      when :migration
        wip.tags["migration-request"] = Time.now.to_s
      else
        raise "Unknown request type: #{type}"
      end

      self.status = :released_to_workspace
      self.save

      return path
    end
  end


end
