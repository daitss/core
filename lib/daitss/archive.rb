require 'daitss/proc/workspace'
require 'daitss/db/ops/entry'

class Archive

  def log message
    e = Entry.new
    e.message = message
    e.save or error "could not save archive log entry"
  end

  # submit a sip on behalf of an agent
  def submit sip_path, agent

    # make a new sip archive
    sa = SipArchive.new sip_path

    # validate account and project outside of class
    agreement_errors = []
    acode = sa.account rescue nil
    pcode = sa.project rescue nil

    unless agent.account.code == acode
      agreement_errors << "cannot submit to account #{acode}"
    end

    unless agent.account.projects.first :code => pcode
      agreement_errors << "cannot submit to project #{pcode}"
    end

    # make a sip with an event
    sip = Sip.from_sip_archive sa
    e = OperationsEvent.new
    e.timestamp = Time.now
    e.operations_agent = agent
    sip.operations_events << e

    if sa.valid? and agreement_errors.empty?
      e.event_name = 'submit'
    else
      e.event_name = 'reject'
      e.notes = (agreement_errors + sa.errors).join "\n"
    end

    if sa.valid?
      uri = "#{Daitss::CONFIG['uri-prefix']}/#{sip.id}"
      wip = Wip.from_sip_archive workspace, sip.id, uri, sa
    end

    sip.save or raise "cannot save sip: #{sip.id}"

    sip
  end

  def workspace
    Workspace.new Daitss::CONFIG['workspace']
  end

end
