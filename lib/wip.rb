require 'forwardable'
require 'fileutils'
require 'fshash'
require 'datafile'

class Wip
  extend Forwardable

  attr_reader :id, :uri, :path, :metadata, :tags

  METADATA_DIR = 'metadata'
  FILES_DIR = 'files'
  TAGS_DIR = 'tags'

  # make a new proto-aip at a path
  def initialize path, uri_prefix
    @path = File.expand_path path
    @id = File.basename @path
    @uri_prefix = uri_prefix
    @uri = URI.join(@uri_prefix, @id).to_s
    FileUtils::mkdir_p @path
    @metadata = FsHash.new File.join(@path, METADATA_DIR)
    @tags = FsHash.new File.join(@path, TAGS_DIR)
  end

  def_delegators :@metadata, :[]=, :[], :has_key?, :delete

  # returns a list of datafiles
  def datafiles
    pattern = File.join @path, FILES_DIR, '*'

    Dir[pattern].map do |path| 
      df_id = File.basename(df_id)
      DataFile.new self, df_id
    end

  end

  # returns a new data file that will persist in this aip
  def new_datafile
    new_id = (datafiles.map { |df| df.id.to_i }.max || 0).to_s
    DataFile.new self, new_id
  end

end
