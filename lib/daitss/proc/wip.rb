require 'forwardable'
require 'fileutils'

require 'daitss/proc/fshash'
require 'daitss/proc/datafile'
require 'daitss/model/package'

require 'daitss/proc/wip/step'

module Daitss

  class Wip
    extend Forwardable

    attr_reader :id, :path, :metadata, :tags, :journal

    METADATA_DIR = 'metadata'
    TAGS_DIR = 'tags'

    FILES_DIR = 'files'
    ORIGINAL_FILES = File.join FILES_DIR, 'original'
    NORMALIZED_FILES = File.join FILES_DIR, 'normalized'
    MIGRATED_FILES = File.join FILES_DIR, 'migrated'
    OLD_XML_RES_DIR = 'xmlresolutions'


    # make a new proto-aip at a path
    def initialize path
      @path = File.expand_path path
      @id = File.basename @path
      FileUtils::mkdir_p @path unless File.exist? @path

      @metadata = FsHash.new File.join(@path, METADATA_DIR)
      @tags = FsHash.new File.join(@path, TAGS_DIR)
      @cached_max_id = {}

      load_journal
    end

    def_delegators :@metadata, :[]=, :[], :has_key?, :delete

    alias_method :to_s, :id

    def == other
      id == other.id and path == other.path
    end
    alias_method :eql?, :==

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

      DataFile.new self, container, id.to_s
    end

  end

end
