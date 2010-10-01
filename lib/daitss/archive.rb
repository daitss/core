require 'digest/sha1'
require 'singleton'

require 'daitss/config'

module Daitss

  class Archive
    include Config
    include Singleton

    def initialize
      load_configuration
      setup_db
    end

    # add an entry into the archive log
    def log message
      e = Entry.new
      e.message = message
      e.save or error "could not save archive log entry"
    end

    def workspace
      @workspace ||= Workspace.new @work_path
    end

    def stashspace

      Dir.chdir stash_path do
        ids = Dir['*'].map { |id| StashBin.new id }
      end

    end

  end

  def archive
    Archive.instance
  end
  module_function :archive

end
