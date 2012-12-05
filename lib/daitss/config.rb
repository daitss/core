require 'daitss/proc/workspace'
require 'daitss/model'
require 'daitss/db'
require 'datyl/config'

module Daitss

  module Config

    # id of system account
    SYSTEM_ACCOUNT_ID = 'SYSTEM'

    # id of system program
    SYSTEM_PROGRAM_ID = 'SYSTEM'

    # daitss1 id
    D1_PROGRAM_ID = 'DAITSS1'

    # id of default operator
    ROOT_OPERATOR_ID = 'daitss'

    # id of default projects
    DEFAULT_PROJECT_ID = 'default'

    attr_reader :ingest_throttle, :dissemination_throttle, :withdrawal_throttle, :queueing_discipline
    attr_reader :db_url, :d1_db_url, :uri_prefix, :http_timeout, :storage_download_timeout, :data_dir, :d1_globals_dir
    attr_reader :log_syslog_facility, :log_filename, :jvm_options, :submit_log_directory, :pulse_log_filename, :mailer_log_filename

    DATA_PATHS = [
      :work,
      :stash,
      :submit,
      :disseminate,
      :dispatch,
      :profile,
      :nuke,
      :reports
    ]
    attr_reader *DATA_PATHS.map { |s| "#{s}_path".to_sym }

    attr_reader :actionplan_url, :describe_url, :storage_url, :viruscheck_url, :transform_url, :xmlresolution_url
    attr_reader :yaml

    
    # load the settings from the file specified by the environment variable DAITSS_CONFIG,
    # and key specified by the environment variable VIRTUAL_HOSTNAME
    def load_configuration
      raise "No DAITSS_CONFIG environment variable has been set, so there's no configuration file to read"             unless ENV['DAITSS_CONFIG']
      raise "The DAITSS_CONFIG environment variable points to a non-existant file, (#{ENV['DAITSS_CONFIG']})"          unless File.exists? ENV['DAITSS_CONFIG']
      raise "The DAITSS_CONFIG environment variable points to a directory instead of a file (#{ENV['DAITSS_CONFIG']})"     if File.directory? ENV['DAITSS_CONFIG']
      raise "The DAITSS_CONFIG environment variable points to an unreadable file (#{ENV['DAITSS_CONFIG']})"            unless File.readable? ENV['DAITSS_CONFIG']

      dconf = Datyl::Config.new(ENV['DAITSS_CONFIG'], :defaults, :database, ENV['VIRTUAL_HOSTNAME'])
 
      # logging
      @log_syslog_facility = dconf.log_syslog_facility
      @log_filename = dconf.log_filename
      @submit_log_directory = dconf.submit_log_directory
      @pulse_log_filename = dconf.pulse_log_filename
      @mailer_log_filename = dconf.mailer_log_filename

      # java options
      @jvm_options = dconf.jvm_options
      
      # database
      @db_url = dconf.daitss_db
      @d1_db_url = dconf.daitss1_db

      # data directories
      @data_dir = dconf.data_dir
      @d1_globals_dir = dconf.d1_globals_dir
 
      DATA_PATHS.each do |sym|
        i_sym = "@#{sym}_path".to_sym
        path = File.join @data_dir, sym.to_s
        instance_variable_set i_sym, path
      end

      # uri prefix
      @uri_prefix = dconf.uri_prefix

      # http timeout value in seconds
      @http_timeout = dconf.http_timeout
      @storage_download_timeout = dconf.storage_download_timeout

      # throttle in number of wips per request

      @ingest_throttle = dconf.ingest_throttle
      @dissemination_throttle = dconf.dissemination_throttle
      @withdrawal_throttle = dconf.withdrawal_throttle

      @queueing_discipline = dconf.queueing_discipline

      # services

      @actionplan_url = dconf.actionplan_url
      @describe_url = dconf.describe_url
      @storage_url = dconf.storage_url
      @viruscheck_url = dconf.viruscheck_url
      @transform_url = dconf.transform_url
      @xmlresolution_url = dconf.xmlresolution_url
    end

    # sets up the database adapter
    def setup_db options={}
      DataMapper::Logger.new $stdout if options[:log]
      adapter = DataMapper.setup :default, @db_url
      adapter.resource_naming_convention = DataMapper::NamingConventions::Resource::UnderscoredAndPluralizedWithoutModule
      DataMapper.finalize
      adapter
    end

    # initializes the database
    def init_db
      DataMapper.auto_migrate!
      # turn on postgres timezone support
      DataMapper.repository(:default).adapter.execute("ALTER TABLE premis_events ALTER datetime TYPE timestamp with time zone")
      DataMapper.repository(:default).adapter.execute("ALTER TABLE datafiles ALTER create_date TYPE timestamp with time zone")
      DataMapper.repository(:default).adapter.execute("ALTER TABLE events ALTER timestamp TYPE timestamp with time zone")
      DataMapper.repository(:default).adapter.execute("ALTER TABLE requests ALTER timestamp TYPE timestamp with time zone")
      DataMapper.repository(:default).adapter.execute("ALTER TABLE entries ALTER timestamp TYPE timestamp with time zone")
      DataMapper.repository(:default).adapter.execute("ALTER TABLE copies ALTER timestamp TYPE timestamp with time zone")
      # create funcitonal index with ieid value on premis_events to speed up query.
      DataMapper.repository(:default).adapter.execute("create index index_ieid on premis_events(substring(premis_events.related_object_id from'................$'))")
      # recreate the relationships_premis_event foreign key contrain to allow cascade delete
      DataMapper.repository(:default).adapter.execute("ALTER TABLE relationships drop constraint relationships_premis_event_fk")
      DataMapper.repository(:default).adapter.execute("ALTER TABLE relationships ADD CONSTRAINT relationships_premis_event_fk FOREIGN KEY (premis_event_id) REFERENCES premis_events (id) ON DELETE CASCADE ON UPDATE CASCADE")
      # manually add the following constraints.  these tables can be linked with either datafile or bitstreams 
      # and datamapper can't create the constraint automatically for us.
      DataMapper.repository(:default).adapter.execute("ALTER TABLE images ADD CONSTRAINT images_datafile_id_fk FOREIGN KEY (datafile_id) REFERENCES datafiles (id) on update cascade on delete cascade");
      DataMapper.repository(:default).adapter.execute("ALTER TABLE images ADD CONSTRAINT images_bitstream_id_fk FOREIGN KEY (bitstream_id) REFERENCES bitstreams (id) on update cascade on delete cascade");
      DataMapper.repository(:default).adapter.execute("ALTER TABLE audios ADD CONSTRAINT audios_datafile_id_fk FOREIGN KEY (datafile_id) REFERENCES datafiles (id) on update cascade on delete cascade");
      DataMapper.repository(:default).adapter.execute("ALTER TABLE audios ADD CONSTRAINT audios_bitstream_id_fk FOREIGN KEY (bitstream_id) REFERENCES bitstreams (id) on update cascade on delete cascade");
      DataMapper.repository(:default).adapter.execute("ALTER TABLE texts ADD CONSTRAINT texts_datafile_id_fk FOREIGN KEY (datafile_id) REFERENCES datafiles (id) on update cascade on delete cascade");
      DataMapper.repository(:default).adapter.execute("ALTER TABLE texts ADD CONSTRAINT texts_bitstream_id_fk FOREIGN KEY (bitstream_id) REFERENCES bitstreams (id) on update cascade on delete cascade");
      DataMapper.repository(:default).adapter.execute("ALTER TABLE documents ADD CONSTRAINT documents_datafile_id_fk FOREIGN KEY (datafile_id) REFERENCES datafiles (id) on update cascade on delete cascade");
      DataMapper.repository(:default).adapter.execute("ALTER TABLE documents ADD CONSTRAINT documents_bitstream_id_fk FOREIGN KEY (bitstream_id) REFERENCES bitstreams (id) on update cascade on delete cascade");
      DataMapper.repository(:default).adapter.execute("ALTER TABLE object_formats ADD CONSTRAINT object_formats_datafile_id_fk FOREIGN KEY (datafile_id) REFERENCES datafiles (id) on update cascade on delete cascade");
      DataMapper.repository(:default).adapter.execute("ALTER TABLE object_formats ADD CONSTRAINT object_formats_bitstream_id_fk FOREIGN KEY (bitstream_id) REFERENCES bitstreams (id) on update cascade on delete cascade");
    end

    # create the stash and work directories in the data dir
    def init_data_dir

      DATA_PATHS.each do |sym|
        i_sym = "@#{sym}_path".to_sym
        p = instance_variable_get i_sym
        FileUtils.mkdir p unless File.directory? p
      end

    end

    # load initial data into the database
    # - system account (with default project)
    # - system program
    # - default operator
    def init_seed

      # account
      a = Account.new(:id => SYSTEM_ACCOUNT_ID,
                      :description => 'account for system operations')

      p = Project.new(:id => DEFAULT_PROJECT_ID,
                      :description => 'default project for system operations',
                      :account => a)

      a.save or raise "cannot save system account"
      p.save or raise "cannot save system project"

      act = Account.new(:id => "ACT",
                      :description => 'sample account')

      prjd = Daitss::Project.new :id => 'default', :description => 'default project for sample account', :account => act

      prj = Project.new(:id => "PRJ",
                      :description => 'sample project',
                      :account => act)

      act.save or raise "cannot save sample account"
      prj.save or raise "cannot save sample project"
      prjd.save or raise "cannot save sample default project"

      # some agents
      program = Program.new(:id => SYSTEM_PROGRAM_ID,
                            :description => "daitss software agent",
                            :account => a)

      program.save or raise "cannot save system program"

      program = Program.new(:id => D1_PROGRAM_ID,
                            :description => "daitss 1 software agent",
                            :account => a)

      program.save or raise "cannot save daitss 1 program"

      operator = Operator.new(:id => ROOT_OPERATOR_ID,
                              :description => "default operator account",
                              :account => a)

      operator.encrypt_auth ROOT_OPERATOR_ID

      operator.save or raise "cannot save system operator"
    end

  end

end
