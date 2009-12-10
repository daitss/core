require 'fileutils'
require 'fshash'
require 'datafile'

class Wip

  attr_reader :path, :metadata, :tags

  AIP_MD_DIR = 'aip-md'
  FILES_DIR = 'files'
  TAGS_DIR = 'tags'

  # make a new proto-aip at a path
  def initialize path
    @path = File.expand_path path
    FileUtils::mkdir_p @path
    @metadata = FsHash.new File.join(@path, AIP_MD_DIR)
    @tags = FsHash.new File.join(@path, TAGS_DIR)
  end

  # returns a list of data files
  def files
    pattern = File.join @path, FILES_DIR, '*'

    Dir[pattern].map do |path| 
      name = File.basename(path)
      DataFile.new self, name
    end

  end

  # returns a new data file that will persist in this aip
  def new_datafile name
    DataFile.new self, name
  end

  def nuke!
    FileUtils::rm_r @path
  end

  def nuked?
    File.exist? @path
  end

end

