require 'wip'
require 'template/premis'

class Wip

  SERVICE_PREMIS_AGENT_ID = 'info:fda/daitss/submission_service'

  def create_submit_agent 
    metadata['submit-agent'] = agent :id => SERVICE_PREMIS_AGENT_ID,
      :name => 'daitss submission service',
      :type => 'Software'
  end

  def create_account_agent 
    metadata['submit-agent-account'] = agent :id => "info:fda/daitss/accounts/#{metadata["dmd-account"]}",
    :name => "DAITSS Account: #{metadata["dmd-account"]}",
    :type => 'Affiliate'
  end

  def create_submit_event 
    metadata['submit-event'] = event :id => "info:fda/#{File.basename(@path)}/event/submit",
    :type => 'submit',
      :outcome => 'success',
      :linking_objects => [ uri ],
      :linking_agents => "info:fda/daitss/accounts/#{metadata["dmd-account"]}"
  end

  def create_accept_event
    metadata['accept-event'] = event :id => "info:fda/#{File.basename(@path)}/event/submit",
    :type => 'archive acceptance',
      :outcome => 'success',
      :linking_objects => [ uri ],
      :linking_agents => SERVICE_PREMIS_AGENT_ID
  end

  def create_package_valid_event 
    metadata['package-valid-event'] = event :id => "info:fda/#{File.basename(@path)}/event/package-valid",
    :type => 'package valid',
      :outcome => 'success',
      :linking_objects => [ uri ],
      :linking_agents => SERVICE_PREMIS_AGENT_ID
  end

  # TODO: this should include the datafile sip name in the event somewhere
  def add_deleted_datafile_event datafile
    metadata["deleted-undescribed-file-#{datafile.id}"] = event :id => "info:fda/#{File.basename(@path)}/event/delete-undescribed-#{datafile.id}",
      :type => 'delete undescribed datafile',
      :outcome => 'success',
      :linking_objects => [ uri ],
      :linking_agents => SERVICE_PREMIS_AGENT_ID
  end

end
