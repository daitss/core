require 'daitss/proc/workspace'
require 'daitss/model'
require 'daitss/db'

module Daitss

  module Config

    # id of system account
    SYSTEM_ACCOUNT_ID = 'SYSTEM'

    # id of system program
    SYSTEM_PROGRAM_ID = 'SYSTEM'

    # daitss1 id
    D1_PROGRAM_ID = 'DAITSS1'

    # id of default operator
    ROOT_OPERATOR_ID = 'root'

    # id of default projects
    DEFAULT_PROJECT_ID = 'default'

    # configuration tokens
    CONFIG_ENV_VAR = 'CONFIG'
    THROTTLE = 'throttle'
    DB_URL = 'database-url'
    DATA_DIR = 'data-dir'
    URI_PREFIX = 'uri-prefix'
    HTTP_TIMEOUT = 'http-timeout'
    ACTIONPLAN_URL = 'actionplan-url'
    DESCRIBE_URL = 'describe-url'
    STORAGE_URL = 'storage-url'
    STATUSECHO_URL = 'statusecho-url'
    VIRUSCHECK_URL = 'viruscheck-url'
    TRANSFORM_URL = 'transform-url'
    XMLRESOLUTION_URL = 'xmlresolution-url'

    attr_reader :db_url, :uri_prefix, :http_timeout, :data_dir

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

    attr_reader :throttle
    attr_reader :actionplan_url, :describe_url, :storage_url, :viruscheck_url, :transform_url, :xmlresolution_url
    attr_reader :yaml

    # load the settings from the file specified
    # by the environment variable CONFIG_ENV_VAR
    def load_configuration
      file = ENV[CONFIG_ENV_VAR] or raise "#{CONFIG_ENV_VAR} environment variable must be set"
      @yaml = YAML.load_file file

      def @yaml.[] key
        super or raise "missing configuration: #{key}"
      end

      # database
      @db_url = @yaml[DB_URL]

      # data directories
      @data_dir = @yaml[DATA_DIR]
      DATA_PATHS.each do |sym|
        i_sym = "@#{sym}_path".to_sym
        path = File.join @data_dir, sym.to_s
        instance_variable_set i_sym, path
      end

      # uri prefix
      @uri_prefix = @yaml[URI_PREFIX]

      # http timeout value in seconds
      @http_timeout = @yaml[HTTP_TIMEOUT]

      # throttle in number of wips
      @throttle = @yaml[THROTTLE]

      # services
      @actionplan_url = @yaml[ACTIONPLAN_URL]
      @describe_url = @yaml[DESCRIBE_URL]
      @storage_url = @yaml[STORAGE_URL]
      @statusecho_url = @yaml[STATUSECHO_URL]
      @viruscheck_url = @yaml[VIRUSCHECK_URL]
      @transform_url = @yaml[TRANSFORM_URL]
      @xmlresolution_url = @yaml[XMLRESOLUTION_URL]
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
                      :description => 'account for system operations',
                      :report_email => 'daitss@localhost')

      p = Project.new(:id => DEFAULT_PROJECT_ID,
                      :description => 'default project for system operations',
                      :account => a)

      a.save or raise "cannot save system account"
      p.save or raise "cannot save system project"

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
