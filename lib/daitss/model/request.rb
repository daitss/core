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
      path = File.join archive.workspace.path, package.id
      wip = Wip.make path, type
      self.status = :released_to_workspace
      self.save
      return path
    end
  end


end
