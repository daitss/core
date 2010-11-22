require 'daitss/model/aip'
require 'daitss/proc/template/descriptor'
require 'daitss/proc/tempdir'

module Daitss

  class Aip

    def Aip.new_from_wip wip
      aip = Aip.new
      aip.package = wip.package
      aip.xml = wip['aip-descriptor']
      aip.datafile_count = wip.represented_datafiles.size

      # get the copy ready
      copy = Copy.new :aip => aip
      copy.url = RandyStore.new_url_for wip.id
      copy.put_to_silo wip
      aip.copy = copy

      if aip.save
        aip
      else
        aip.copy.delete_from_silo
        raise "could not save aip: #{aip.errors.size} errors\n #{aip.errors.to_a.join "\n"}"
      end

    end

    def Aip.update_from_wip wip
      aip = wip.package.aip or raise 'cannot access aip'
      aip.xml = wip['aip-descriptor']
      aip.datafile_count = wip.represented_datafiles.size

      # get the copy ready
      copy = aip.copy
      old_revision = copy.revision
      copy.revision = old_revision.next
      copy.put_to_silo wip
      aip.copy = copy

      if aip.save
        aip.copy.delete_from_silo old_revision
        aip
      else
        aip.copy.delete_from_silo
        raise "could not save aip: #{aip.errors.size} errors\n #{aip.errors.to_a.join "\n"}"
      end

    end

  end

end
