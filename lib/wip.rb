require 'forwardable'
require 'fileutils'
require 'fshash'
require 'datafile'

class Wip
  extend Forwardable

  attr_reader :id, :path, :metadata, :tags

  METADATA_DIR = 'metadata'
  FILES_DIR = 'files'
  TAGS_DIR = 'tags'

  # make a new proto-aip at a path
  def initialize path, uri
    @path = File.expand_path path
    @id = File.basename @path
    FileUtils::mkdir_p @path
    @metadata = FsHash.new File.join(@path, METADATA_DIR)
    @tags = FsHash.new File.join(@path, TAGS_DIR)
    @metadata['uri'] = URI.parse(uri).to_s
  end

  def_delegators :@metadata, :[]=, :[], :has_key?, :delete

  # returns a list of datafiles
  def datafiles
    pattern = File.join @path, FILES_DIR, '*'

    Dir[pattern].map do |path| 
      df_id = File.basename path
      DataFile.new self, df_id
    end

  end

  # returns a new data file that will persist in this aip
  def new_datafile
    max_id = (datafiles.map { |df| df.id.to_i }.max || -1)
    new_id = max_id + 1
    DataFile.new self, new_id.to_s
  end

  def uri
    metadata['uri']
  end

  alias_method :to_s, :uri

end
