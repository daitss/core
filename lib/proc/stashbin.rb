require 'uri'
require 'proc/wip'
require 'enumerator'

module Daitss

  class StashBin

    def StashBin.make! name
      id = URI.encode name
      path = File.join Daitss.archive.stash_path, id
      FileUtils.mkdir path
      StashBin.new id
    end

    include Enumerable

    attr_reader :id

    def initialize id
      @id = id
      raise "bin #{id} does not exist" unless File.directory? path
    end

    def name
      URI.decode id
    end
    alias_method :to_s, :name

    def path
      File.join Daitss.archive.stash_path, @id
    end

    def delete
      FileUtils.rmdir path
    end

    def each
      pattern = File.join path, '*'

      Dir[pattern].each do |p|
        wip = Wip.new p
        yield wip
      end

    end

    def empty?
      not any?
    end

    def size
      to_a.size
    end

    def unstash wip_id
      src = File.join path, wip_id
      dst = File.join Daitss.archive.workspace.path, wip_id
      FileUtils.mv src, dst
      Package.get(wip_id).log "unstash"
    end

  end

end
