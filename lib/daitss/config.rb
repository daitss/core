require 'daitss/proc/workspace'
require 'daitss/model'
require 'daitss/db'

module Daitss

  module Config

    # name of directory for workspace
    WORK_DIR = "work"

    # name of directory for stashspace
    STASH_DIR = "stash"

    # name of the directory for submissions
    SUBMIT_DIR = 'submit'

    # name of the directory for submissions
    DISPATCH_DIR = 'dispatch'

    # name of the directory for dips
    DISSEMINATE_DIR = 'disseminate'

    # id of system account
    SYSTEM_ACCOUNT_ID = 'SYSTEM'

    # id of system program
    SYSTEM_PROGRAM_ID = 'SYSTEM'

    # id of default operator
    ROOT_OPERATOR_ID = 'root'

    # id of default projects
    DEFAULT_PROJECT_ID = 'default'

    # configuration tokens
    CONFIG_ENV_VAR = 'CONFIG'
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

    attr_reader :db_url, :uri_prefix, :http_timeout
    attr_reader :data_dir, :work_path, :stash_path, :submit_path, :disseminate_path, :dispatch_path
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
      @work_path = File.join @data_dir, WORK_DIR
      @stash_path = File.join @data_dir, STASH_DIR
      @submit_path = File.join @data_dir, SUBMIT_DIR
      @disseminate_path = File.join @data_dir, DISSEMINATE_DIR
      @dispatch_path = File.join @data_dir, DISPATCH_DIR

      # uri prefix
      @uri_prefix = @yaml[URI_PREFIX]

      # http timeout value in seconds
      @http_timeout = @yaml[HTTP_TIMEOUT]

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
    end

    # create the stash and work directories in the data dir
    def init_data_dir

      [ @work_path,
        @stash_path,
        @submit_path,
        @disseminate_path,
        @dispatch_path
      ].each do |p|
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

      operator = Operator.new(:id => ROOT_OPERATOR_ID,
                              :auth_key => Digest::SHA1.hexdigest(ROOT_OPERATOR_ID),
                              :description => "default operator account",
                              :account => a)

      operator.save or raise "cannot save system operator"
    end

  end

end
