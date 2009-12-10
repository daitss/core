require 'fshash'
require 'fileutils'

class DataFile
  include Transform

  attr_reader :wip, :path, :name, :metadata

  def initialize wip, name
    @wip = wip
    @name = name
    @metadata = FsHash.new File.join(@wip.path, 'file-md', name)
    @path = File.join @wip.path, 'files', name
    FileUtils::mkdir_p @path
  end

end
