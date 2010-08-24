require 'libxml'

require 'daitss/model/aip'
require 'daitss/proc/sip_archive'
require 'daitss/proc/template/premis'
require 'daitss/proc/wip'
require 'daitss/xmlns'

include LibXML

class Wip

  # Create an AIP from a sip archive
  def Wip.from_sip_archive workspace, id, uri, sip_archive

    begin
      path = File.join workspace.submit_dir, id
      wip = Wip.new path, uri
      wip['sip-name'] = sip_archive.name
      wip.task = :ingest

      sip_archive.files.each_with_index do |f, index|
        next unless File.exists? File.join(sip_archive.path, f)

        df = wip.new_original_datafile index

        df.open('w') do |o|
          sip_file_path = File.join sip_archive.path, f
          sip_file_data = File.read sip_file_path
          o.write sip_file_data
        end

        df['sip-path'] = f
        df['aip-path'] = File.join Aip::SIP_FILES_DIR, f
      end

      # put metadata from SIP in WIP
      wip["dmd-account"] = sip_archive.account
      wip["dmd-project"] = sip_archive.project
      wip["dmd-title"] = sip_archive.title
      wip["dmd-issue"] = sip_archive.issue
      wip["dmd-volume"] = sip_archive.volume
      wip["dmd-entity-id"] = sip_archive.entity_id
      wip['sip-descriptor'] = File.read sip_archive.descriptor_file

      # make submit premis md
      agent_uri = "info:fda/daitss/account/#{wip["dmd-account"]}"

      wip['submit-event'] = event(
        :id => "#{uri}/event/submit",
        :type => 'submit',
        :outcome => 'success',
        :linking_objects => [ uri ],
        :linking_agents => agent_uri
      )

      wip['submit-agent'] = agent(
        :id => agent_uri,
        :name => "DAITSS Account: #{wip["dmd-account"]}",
        :type => 'Affiliate'
      )

      # move to workspace dir
      new_path = File.join workspace.path, wip.id
      FileUtils.mv path, new_path

      Wip.new new_path
    rescue
      FileUtils.rm_r path if File.exist? path
      FileUtils.rm_r new_path if FIle.exist? new_path
      raise
    end

  end

end
