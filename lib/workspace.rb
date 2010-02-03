require 'wip'
require 'wip/task'

class Workspace

  attr_reader :path

  def initialize path
    @path = path
  end

  def each

    Dir[ File.join(@path, "*") ].each do |path|
      wip = Wip.new path
      yield wip
    end

  end
  include Enumerable

  def wip_by_id id
    wip_path = File.join @path, id

    if File.exist? wip_path
      Wip.new wip_path
    end

  end
  alias_method :[], :wip_by_id

  def stash wip_id, dir
    raise "wip #{wip_id} does not exist" unless self[wip_id]
    FileUtils::mv self[wip_id].path, dir
  end

  def unstash wip_path
    FileUtils::mv wip_path, path
  end

end
