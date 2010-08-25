require 'net/http'

require 'daitss/model/aip'
require 'daitss/proc/template/descriptor'
require 'daitss/proc/tempdir'

class Aip

  def Aip.new_from_wip wip
    aip = Aip.new
    aip.package = wip.package
    aip.uri = wip.uri
    aip.xml = wip['aip-descriptor']
    aip.number_of_datafiles = wip.represented_datafiles.size

    # get the copy ready
    aa = AipArchive.new wip

    copy = Copy.new
    copy.size = aa.size
    copy.md5 = aa.md5
    copy.sha1 = aa.sha1

    copy.put_to_silo

    aip.copy = copy

    if aip.save
      aip
    else
      aip.copy.delete_from_silo
      raise "could not save aip: #{aip.errors.size} errors\n#{aip.errors.join "\n"}"
    end

  end

  def Aip.update_from_wip wip
    aip = Aip.get! wip.id
    aip.xml = wip['aip-descriptor']
    aip.number_of_datafiles = wip.represented_datafiles.size

    # get the copy ready
    aa = AipArchive.new wip
    old_revision = copy.revision

    copy = aip.copy
    copy.revision += 1
    copy.size = aa.size
    copy.md5 = aa.md5
    copy.sha1 = aa.sha1

    copy.put_to_silo

    aip.copy = copy

    if aip.save
      aip.copy.delete_from_silo old_revision
      aip
    else
      aip.copy.delete_from_silo
      raise "could not save aip: #{aip.errors.size} errors\n#{aip.errors.join "\n"}"
    end

  end

end
