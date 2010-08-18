require 'forwardable'
require 'fileutils'

require 'daitss/proc/fshash'
require 'daitss/proc/datafile'

class Wip
  extend Forwardable

  attr_reader :id, :path, :metadata, :tags

  METADATA_DIR = 'metadata'
  TAGS_DIR = 'tags'

  FILES_DIR = 'files'
  ORIGINAL_FILES = File.join FILES_DIR, 'original'
  NORMALIZED_FILES = File.join FILES_DIR, 'normalized'
  MIGRATED_FILES = File.join FILES_DIR, 'migrated'

  # make a new proto-aip at a path
  def initialize path, uri=nil
    @path = File.expand_path path
    @id = File.basename @path
    FileUtils::mkdir_p @path unless File.exist? @path

    @metadata = FsHash.new File.join(@path, METADATA_DIR)
    @tags = FsHash.new File.join(@path, TAGS_DIR)

    if uri
      raise "wip #{@path} has a uri" if metadata.has_key? 'uri'
      metadata['uri'] = uri
    else
      raise "wip #{@path} has no uri" unless metadata.has_key? 'uri'
    end

    @cached_max_id = {}

  end

  def_delegators :@metadata, :[]=, :[], :has_key?, :delete

  def uri
    metadata['uri']
  end
  alias_method :to_s, :uri

  def == other
    id == other.id and uri == other.uri and path == other.path
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
    SubmittedSip.first :id => id
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
