require 'wip'
require 'wip/submission_metadata'
require 'wip/sip_descriptor'
require 'fileutils'

class Wip

  # deletes from wip those files that are undescribed, creating premis events for each. returns the number of files deleted
  def trim_undescribed_datafiles
    described = described_datafiles
    package_name = metadata["sip-name"]
    delete_count = 0

    original_datafiles.each do |datafile|
      unless described.include? datafile or datafile["sip-path"] =~ /^#{package_name}.xml$/i
        delete_datafile datafile
        # create event for datafile deletion
        
        delete_count += 1
      end

    end

    return delete_count
  end

  private

  def delete_datafile datafile
    FileUtils.rm_rf File.dirname(datafile.datapath)
  end
end
