require 'daitss/proc/workspace'
require 'daitss/model/entry'

class Archive

  def Archive.setup_db options={}
    DataMapper::Logger.new $stdout if options[:log]
    adapter = DataMapper.setup :default, Daitss::CONFIG['database-url']
    #adapter.resource_naming_convention = UnderscoredAndPluralizedWithoutModule
  end

  def log message
    e = Entry.new
    e.message = message
    e.save or error "could not save archive log entry"
  end

  # submit a sip on behalf of an agent, return a package
  def submit sip_path, agent

    # make a new sip archive
    sa = SipArchive.new sip_path

    # validate account and project outside of class
    agreement_errors = []
    a_id = sa.account rescue nil
    p_id = sa.project rescue nil

    package = Package.new

    unless agent.account.id == a_id
      agreement_errors << "cannot submit to account #{a_id}"
    end

    project = agent.account.projects.first :id => p_id

    if project
      package.project = project
    else
      package.project = agent.account.default_project
      agreement_errors << "cannot submit to project #{p_id}"
    end

    package.sip = Sip.new :name => sa.name
    package.sip.number_of_datafiles = sa.files.size rescue nil
    package.sip.size_in_bytes = sa.size_in_bytes rescue nil

    if sa.valid? and agreement_errors.empty?
      uri = "#{Daitss::CONFIG['uri-prefix']}/#{package.id}"
      wip = Wip.from_sip_archive workspace, package.id, uri, sa
      package.log 'submit', :agent => agent
    else
      combined_errors = (agreement_errors + sa.errors).join "\n"
      package.log 'reject', :agent => agent, :notes => combined_errors
    end

    unless package.save
      FileUtils.rm_r wip.path
      raise "cannot save package: #{package.id}"
    end

    package
  end

  def workspace
    Workspace.new Daitss::CONFIG['workspace']
  end

  def stashspace
    Daitss::CONFIG['stashspace']
  end

end
