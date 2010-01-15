require 'forwardable'
require 'fshash'
require 'fileutils'
require 'wip'

class DataFile

  extend Forwardable

  attr_reader :id, :uri, :wip, :metadata, :datapath 
  alias_method :to_s, :uri

  METADATA_DIR = 'metadata'
  DATA_FILE = 'data'

  def initialize wip, id
    @id = id
    @wip = wip
    @uri = @wip.uri + '/file/' + @id
    @dir = File.join @wip.path, Wip::FILES_DIR, @id
    @metadata = FsHash.new File.join(@dir, METADATA_DIR)
    @datapath = File.join @dir, DATA_FILE
    FileUtils::touch @datapath
  end

  def_delegators :@metadata, :[]=, :[], :has_key?, :delete

  def open mode="r"

    if block_given?
      Kernel::open(@datapath, mode) { |io| yield io }
    else
      Kernel::open @datapath, mode
    end

  end

  def == other
    #puts "#{id} #{other.id} => #{id == other.id}"
    #puts "#{wip} #{other.wip} => #{wip == other.wip}"
    id == other.id and wip == other.wip
  end
  alias_method :eql?, :==

end
