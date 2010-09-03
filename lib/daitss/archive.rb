require 'daitss/proc/workspace'
require 'daitss/model/entry'

class Archive

  WORK_DIR = "work"
  STASH_DIR = "stash"

  def Archive.work_path
    File.join Daitss::CONFIG["data"], WORK_DIR
  end

  def Archive.stash_path
    File.join Daitss::CONFIG["data"], STASH_DIR
  end

  def Archive.setup_db options={}
    DataMapper::Logger.new $stdout if options[:log]
    adapter = DataMapper.setup :default, Daitss::CONFIG['database-url']
    #adapter.resource_naming_convention = UnderscoredAndPluralizedWithoutModule
  end

  def Archive.init_db
    DataMapper.auto_migrate!
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
    Workspace.new Archive.work_path
  end

  def stashspace
    Archive.stash_path
  end

end
