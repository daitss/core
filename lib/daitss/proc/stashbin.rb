require 'uri'
require 'daitss/proc/wip'
require 'daitss/archive'
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
      Dir.entries(path).length - 2
    end

    def unstash wip_id, agent, note
      src = File.join path, wip_id
      dst = File.join Daitss.archive.workspace.path, wip_id
      FileUtils.mv src, dst

      if note and !note.empty?
        Package.get(wip_id).log "unstash", :agent => agent, :notes => note
      else
        Package.get(wip_id).log "unstash", :agent => agent
      end

    end

  end

end
