require 'daitss/proc/workspace'

class Archive

  # submit a sip on behalf of an agent
  def submit sip_path, agent

    # make a new sip archive
    sa = SipArchive.new sip_path

    # make a sip with an event
    sip = Sip.from_sip_archive sa
    e = OperationsEvent.new
    e.timestamp = Time.now
    e.operations_agent = agent
    sip.operations_events << e

    if sa.valid?
      e.event_name = 'submit'
    else
      e.event_name = 'reject'
      e.notes = sa.errors
    end

    if sa.valid?
      uri = "#{Daitss::CONFIG['uri-prefix']}/#{sip.id}"
      wip = Wip.from_sip_archive workspace, sip.id, uri, sa
    end

    sip.save or raise "cannot save sip: #{sip.id}"

    sip
  rescue => e
    debugger
    FileUtils.rm_r wip.path
    raise
  end

  def workspace
    Workspace.new Daitss::CONFIG['workspace']
  end

end
