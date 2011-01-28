require 'digest/sha1'
require 'singleton'

require 'daitss/config'

module Daitss

  class Archive

    @@dont_configure = false
    def Archive.dont_configure!
      @@dont_configure = true
    end

    include Config
    include Singleton

    def initialize

      unless @@dont_configure
        load_configuration
        setup_db
      end

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

  alias_method :load_archive, :archive
  module_function :archive
  module_function :load_archive

end
