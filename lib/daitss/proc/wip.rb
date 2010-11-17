require 'forwardable'
require 'fileutils'

require 'daitss/proc/fshash'
require 'daitss/proc/datafile'
require 'daitss/model/package'

require 'daitss/proc/statevar'
require 'daitss/proc/wip/journal'
require 'daitss/proc/wip/process'

require 'daitss/proc/wip/ingest'
require 'daitss/proc/wip/disseminate'

module Daitss

  class Wip
    extend Forwardable
    extend StateVar

    METADATA_DIR = 'metadata'
    FILES_DIR = 'files'
    ORIGINAL_FILES = File.join FILES_DIR, 'original'
    NORMALIZED_FILES = File.join FILES_DIR, 'normalized'
    MIGRATED_FILES = File.join FILES_DIR, 'migrated'
    OLD_XML_RES_DIR = 'xmlresolutions'

    attr_reader :id, :path, :metadata

    def_delegators :@metadata, :[]=, :[], :has_key?, :delete

    state_var :info, :default => {}
    state_var :journal, :default => {}
    state_var :process

    VALID_TASKS = [
      :sleep,
      :ingest,
      :disseminate,
      :withdraw,
      :peek,
      :migration
    ]

    # make a new wip on the filesystem
    def Wip.make path, task

      unless VALID_TASKS.include? task
        raise "Unknown task: #{task}"
      end

      FileUtils.mkdir path

      Dir.chdir path do

        [ METADATA_DIR,
          FILES_DIR,
          ORIGINAL_FILES,
          NORMALIZED_FILES,
          MIGRATED_FILES,
          OLD_XML_RES_DIR
        ].each do |f|
          FileUtils.mkdir f
        end

      end

      w = Wip.new path

      w.instance_eval do
        @info[:task] = task
        save_info
      end

      w
    end

    # initialize a wip object from a filesystem wip
    def initialize path
      @path = File.expand_path path
      @id = File.basename @path

      @metadata = FsHash.new File.join(@path, METADATA_DIR)
      @cached_max_id = {}

      load_info
      load_journal
      load_process
    end
    alias_method(:to_s, :id)

    def == other
      id == other.id and path == other.path
    end
    alias_method(:eql?, :==)

    def task
      @info[:task]
    end

    # return an array of the original datafiles
    def original_datafiles
      datafiles ORIGINAL_FILES
    end

    # add a new original datafile
    def new_original_datafile id
      new_datafile ORIGINAL_FILES, id
    end

    # return an array of the migrated datafiles
    def migrated_datafiles
      datafiles MIGRATED_FILES
    end

    # add a new migrated datafile
    def new_migrated_datafile id
      new_datafile MIGRATED_FILES, id
    end

    # return an array of the normalized datafiles
    def normalized_datafiles
      datafiles NORMALIZED_FILES
    end

    # add a new normalized datafile
    def new_normalized_datafile id
      new_datafile NORMALIZED_FILES, id
    end

    def all_datafiles
      original_datafiles + normalized_datafiles + migrated_datafiles
    end

    # return the sip this wip belongs to
    def package
      Package.get id
    end

    # return the stashbin if in one
    def bin
      dir = File.dirname path
      bins = Daitss.archive.stashspace
      bins.find { |b| b.path == dir }
    end

    def stashed?
      not bin.nil?
    end

    def old_xml_res_tarball_dir
      File.join(path, OLD_XML_RES_DIR)
    end

    def old_xml_res_tarballs
      pattern = File.join old_xml_res_tarball_dir, '*'
      Dir[pattern]
    end

    private

    def datafiles container
      pattern = File.join @path, container, '*'

      Dir[pattern].map do |path|
        df_id = File.basename path
        DataFile.new self, container, df_id
      end
    end

    def new_datafile container, id

      if File.exist? File.join(@path, container, id.to_s)
        raise "datafile #{id} already exists in #{container}"
      end

      DataFile.make self, container, id.to_s
    end

  end

end
