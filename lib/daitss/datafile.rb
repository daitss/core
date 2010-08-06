require 'forwardable'
require 'fshash'
require 'fileutils'
require 'wip'
require 'datafile/obsolete'

class DataFile

  extend Forwardable

  attr_reader :id, :uri, :wip, :metadata, :datapath
  alias_method :to_s, :uri
  alias_method :inspect, :uri

  METADATA_DIR = 'metadata'
  DATA_FILE = 'data'

  def initialize wip, container, id
    @id = id
    @wip = wip
    @uri = @wip.uri + '/file/' + @id
    @dir = File.join @wip.path, container, @id
    @metadata = FsHash.new File.join(@dir, METADATA_DIR)
    @datapath = File.join @dir, DATA_FILE
    FileUtils::touch @datapath
  end

  def_delegators :@metadata, :[]=, :[], :has_key?, :delete

  # open the datafile, see Kernel#open for more details
  def open mode="r"

    if block_given?
      Kernel::open(@datapath, mode) { |io| yield io }
    else
      Kernel::open @datapath, mode
    end

  end

  # remove a datafile from the wip
  def nuke!

    if @dir == File.join(@wip.path, Wip::ORIGINAL_FILES, id)
      raise "cannot nuke an original datafile"
    else
      FileUtils::rm_r @dir
    end

  end

  # the size in bytes of the datafile
  def size
    File.size @datapath
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
  alias_method :eql?, :==

  def hash
    @dir.hash
  end

end
