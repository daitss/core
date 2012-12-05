require 'forwardable'
require 'fileutils'

require 'mixin/file'

require 'daitss/proc/fshash'
require 'daitss/proc/datafile'
require 'daitss/model/package'

require 'daitss/proc/fileattr'
require 'daitss/proc/statevar'
require 'daitss/proc/wip/journal'
require 'daitss/proc/wip/process'

require 'daitss/proc/wip/ingest'
require 'daitss/proc/wip/disseminate'
require 'daitss/proc/wip/withdraw'

require 'daitss/proc/wip/queue_report.rb'

module Daitss

  class Wip
    extend Forwardable
    extend StateVar
    extend FileAttr

    METADATA_DIR = 'metadata'
    FILES_DIR = 'files'
    ORIGINAL_FILES = File.join FILES_DIR, 'original'
    NORMALIZED_FILES = File.join FILES_DIR, 'normalized'
    MIGRATED_FILES = File.join FILES_DIR, 'migrated'
    OLD_XML_RES_DIR = 'xmlresolutions'

    attr_reader :id, :path, :metadata

    attr_accessor :file_group

    def_delegators :@metadata, :[]=, :[], :has_key?, :delete

    state_var :info, :default => {}
    state_var :journal, :default => {}
    state_var :process

    file_attr :tarball
    file_attr :xmlres

    md_file_attr :aip_descriptor
    md_file_attr :aip_descriptor_errata

    VALID_TASKS = [
      :sleep,
      :ingest,
      :disseminate,
      :withdraw,
      :peek
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
      w.info[:task] = task
      w.save_info
      w
    end

    # initialize a wip object from a filesystem wip
    def initialize path
      @path = File.expand_path path
      @id = File.basename @path
      @metadata_path = File.join @path, METADATA_DIR

      @metadata = FsHash.new File.join(@path, METADATA_DIR)
      @cached_max_id = {}

      File.lock @path, :shared => true do
        load_info
        load_journal
        load_process
      end

    end

    alias_method(:to_s, :id)

    def == other
      id == other.id and path == other.path
    end
    alias_method(:eql?, :==)

    def task
      @info[:task]
    end

    # @return [Array] the original datafiles
    def original_datafiles
      datafiles ORIGINAL_FILES
    end

    # add a new original datafile
    #
    # @param [String] id of the new datafile
    def new_original_datafile id
      new_datafile ORIGINAL_FILES, id
    end

    # @return [Array] the migrated datafiles
    def migrated_datafiles
      datafiles MIGRATED_FILES
    end

    # add a new migrated datafile
    #
    # @param [String] id of the new datafile
    def new_migrated_datafile id    
      new_datafile_override MIGRATED_FILES, id
    end

    # @return [Array] the normalized datafiles
    def normalized_datafiles
      datafiles NORMALIZED_FILES
    end

    # add a new normalized datafile
    #
    # @param [String] id of the new datafile
    def new_normalized_datafile id
      new_datafile_override NORMALIZED_FILES, id
    end

    # @return [Array] all datafiles
    def all_datafiles
      original_datafiles + normalized_datafiles + migrated_datafiles
    end

    # @return [Package] the package this wip is operating on
    def package
      @package ||= Package.get id
    end

    # @return [StashBin] the stashbin containing this wip if stashed
    def bin
      dir = File.dirname path
      bins = archive.stashspace
      bins.find { |b| b.path == dir }
    end

    # @return [Boolean] true if it is stashed
    def stashed?
      not bin.nil?
    end

    # @return [String] the direcetory containing any old xml resolution tarballs
    def old_xml_res_tarball_dir
      File.join @path, OLD_XML_RES_DIR
    end

    # @return [Array] any old xml resolution tarballs
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

    # create a new datafile, if a file with the same name already exist, override it
    def new_datafile_override container, id
      newfile = File.join(@path, container, id.to_s)
      if File.exist? newfile
       FileUtils.rm_r newfile
      end
      DataFile.make self, container, id.to_s
    end

    def new_datafile container, id
       if File.exist? File.join(@path, container, id.to_s)
         raise "datafile #{id} already exists in #{container}" unless (task == :disseminate)
       end

       DataFile.make self, container, id.to_s
     end
  end

end
