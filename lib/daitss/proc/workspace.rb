require 'daitss/proc/wip'

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

        begin
          wip = Wip.new path
          yield wip
        rescue Errno::ENOENT => e
          next
        end

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
    def stash wip_id, bin, note=nil, agent=nil
      src = File.join path, wip_id
      dst = File.join bin.path, wip_id
      FileUtils.mv src, dst

      agent = Program.get("SYSTEM") unless agent 

      if note and !note.empty?
        Package.get(wip_id).log "stash", :notes => "stashed to #{bin.name}\n#{note}", :agent => agent
      else
        Package.get(wip_id).log "stash", :notes => "stashed to #{bin.name}", :agent => agent
      end

    end

    def to_json *a
      map.to_json *a
    end

  end

end
