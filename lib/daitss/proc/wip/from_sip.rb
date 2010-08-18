require 'libxml'

require 'daitss/proc/sip_archive'
require 'daitss/db/ops/aip'
require 'daitss/proc/wip'
require 'daitss/xmlns'

include LibXML

class Wip

  # Create an AIP from a sip
  def Wip.from_sip_archive path, uri, sip_archive
    wip = Wip.new path, uri
    wip['sip-name'] = sip.name

    sip.files.each_with_index do |f, index|
      next unless File.exists? File.join(sip.path, f)

      df = wip.new_original_datafile index

      df.open('w') do |o|
        sip_file_path = File.join sip.path, f
        sip_file_data = File.read sip_file_path
        o.write sip_file_data
      end

      df['sip-path'] = f
      df['aip-path'] = File.join Aip::SIP_FILES_DIR, f
    end

    # put metadata from SIP in WIP
    wip["dmd-account"] = sip.account
    wip["dmd-project"] = sip.project
    wip["dmd-title"] = sip.title
    wip["dmd-issue"] = sip.issue
    wip["dmd-volume"] = sip.volume
    wip["dmd-entity-id"] = sip.entity_id
    wip['sip-descriptor'] = File.read sip.descriptor_file

    wip
  end

end
