require 'digest/sha1'

require 'daitss/proc/workspace'
require 'daitss/model'
require 'daitss/db'

class Archive

  WORK_DIR = "work"

  STASH_DIR = "stash"

  SYSTEM_ACCOUNT_ID = 'SYSTEM'
  SYSTEM_PROGRAM_ID = 'SYSTEM'
  ROOT_OPERATOR_ID = 'root'

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

  def Archive.create_work_directories

    unless File.directory? Archive.work_path
      FileUtils.mkdir Archive.work_path
    end

    unless File.directory? Archive.stash_path
      FileUtils.mkdir Archive.stash_path
    end

  end

  def Archive.create_initial_data
    a = Account.new(:id => SYSTEM_ACCOUNT_ID,
                    :description => 'account for system operations')
    a.save or raise "cannot save system account"

    p = Program.new(:id => SYSTEM_PROGRAM_ID,
                    :description => "daitss software agent",
                    :account => a)
    p.save or raise "cannot save system program agent"

    u = Operator.new(:id => ROOT_OPERATOR_ID,
                     :auth_key => Digest::SHA1.hexdigest(ROOT_OPERATOR_ID),
                     :description => "default operator account",
                     :account => a)
    u.save or raise "cannot save system operator agent"
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

    if agent.kind_of? Operator
      account = Account.get(a_id)
      package.project = account.projects.first :id => p_id
    else

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
