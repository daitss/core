require 'forwardable'
require 'fileutils'

require 'daitss/proc/fshash'
require 'daitss/proc/wip'
require 'daitss/proc/fileattr'
require 'daitss/proc/datafile/obsolete'

module Daitss

  class DataFile

    extend Forwardable
    extend FileAttr

    attr_reader :id, :uri, :wip, :metadata
    alias_method :to_s, :uri
    alias_method :inspect, :uri

    METADATA_DIR = 'metadata'
    file_attr :data

    def DataFile.make wip, container, id
      path = File.join wip.path, container, id
      FileUtils.mkdir_p path
      FileUtils.mkdir_p File.join path, METADATA_DIR
      df = DataFile.new wip, container, id
      FileUtils.touch df.data_file
      df
    end

    def initialize wip, container, id
      @id = id
      @wip = wip
      @uri = @wip.package.uri + '/file/' + @id
      @path = File.join @wip.path, container, @id
      @metadata_path = File.join @path, METADATA_DIR
      @metadata = FsHash.new @metadata_path
      @is_sip_descriptor = metadata['sip-path'] == @wip.package.sip.name + '.xml'
    end

    def_delegators :@metadata, :[]=, :[], :has_key?, :delete

    # open the datafile, see Kernel#open for more details
    def open mode="r"

      if block_given?
        Kernel::open(data_file, mode) { |io| yield io }
      else
        Kernel::open data_file, mode
      end

    end

    # remove a datafile from the wip
    def nuke!

      if @dir == File.join(@wip.path, Wip::ORIGINAL_FILES, id)
        raise "cannot nuke an original datafile"
      else
        FileUtils::rm_r @dir if @dir
      end

    end

    # the size in bytes of the datafile
    def size
      File.size data_file
    end

    # a datafile that is a migrated version of this
    def migrated_version
      mdfs = @wip.migrated_datafiles.select { |df| df['transformation-source'] == uri }
      mdfs.find { |df| not df.obsolete? }
    end

    # a datafile that is a normalized version version of this
    def normalized_version
      ndfs = @wip.normalized_datafiles.select { |df| df['transformation-source'] == uri }
      ndfs.find { |df| not df.obsolete? }
    end

    # returns true if other is the same datafile
    def == other
      id == other.id and wip == other.wip
    end
    alias_method(:eql?, :==)

    def hash
      @dir.hash
    end

    def sip_descriptor?
      @is_sip_descriptor
    end

  end

end
