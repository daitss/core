require 'forwardable'
require 'fileutils'
require 'fshash'
require 'datafile'

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

  end

  def_delegators :@metadata, :[]=, :[], :has_key?, :delete

  # returns a list of datafiles
  def original_datafiles
    pattern = File.join @path, ORIGINAL_FILES, '*'

    Dir[pattern].map do |path|
      df_id = File.basename path
      DataFile.new self, df_id
    end

  end

  # returns a new data file that will persist in this aip
  # if two processes are calling this method it will produce unspecified results
  def new_original_datafile id=nil

    df_id = if id
              id
            else
              @cached_max_id ||= (original_datafiles.map { |df| df.id.to_i }.max || -1)
              @cached_max_id += 1
            end

    DataFile.new self, df_id.to_s
  end

  def remove_datafile df_to_remove

    unless datafiles.find { |df| df == df_to_remove }
      raise "datafile #{df_to_remove} is not of wip #{self}"
    end

    FileUtils::rm_r File.join @path, FILES_DIR, df_to_remove.id
  end

  def uri
    metadata['uri']
  end

  alias_method :to_s, :uri

  def == other
    id == other.id and uri == other.uri and path == other.path
  end
  alias_method :eql?, :==

end
