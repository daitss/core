require 'daitss/proc/wip'
require 'daitss/proc/wip/submission_metadata'
require 'daitss/proc/wip/sip_descriptor'
require 'fileutils'

class Wip

  # deletes from wip those files that are undescribed, creating premis events for each. returns the number of files deleted
  def trim_undescribed_datafiles
    described = described_datafiles
    package_name = metadata["sip-name"]
    deleted_count = 0

    original_datafiles.each do |datafile|
      unless described.include? datafile or datafile["sip-path"] =~ /^#{package_name}.xml$/i
        add_deleted_datafile_event datafile
        delete_datafile datafile
        deleted_count += 1

      end

    end

    return deleted_count
  end

  private

  def delete_datafile datafile
    FileUtils.rm_rf File.dirname(datafile.datapath)
  end
end
