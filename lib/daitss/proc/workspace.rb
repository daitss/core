require 'daitss/proc/wip'
require 'daitss/proc/wip/task'

module Daitss

  class Workspace

    attr_reader :path

    def initialize path
      raise "#{path} must be a directory" unless File.directory? path
      @path = path
    end

    def has_wip? wip_id
      wip_path = File.join @path, wip_id
      File.exist? wip_path
    end

    def each

      Dir[ File.join(@path, "*") ].each do |path|
        wip = Wip.new path
        yield wip
      end

    end
    include Enumerable

    def wip_by_id wip_id

      if has_wip? wip_id
        Wip.new File.join(@path, wip_id)
      end

    end
    alias_method :[], :wip_by_id

    # move the wip in the stash bin
    def stash wip_id, bin
      src = File.join path, wip_id
      dst = File.join bin.path, wip_id
      FileUtils.mv src, dst
    end

    def to_json *a
      map.to_json *a
    end

  end

end
