require 'yaml'

module Daitss

  class Configuration < Hash

    ENV_VAR = 'CONFIG'

    def load file
      merge! YAML.load_file file

      # sane defaults
      CONFIG['http-timeout'] ||= 60 * 10 # 10 minutes
      Daitss::CONFIG["database-url"] ||= 'sqlite3::memory:'

      # jvm options, for this to work it must be ran before any other rjb code
      if Daitss::CONFIG["jvm-options"]
        require 'rjb'
        Rjb.load '.', Daitss::CONFIG["jvm-options"]
      end

    end

    def load_from_env
      raise "#{ENV_VAR} environment variable must be set" unless ENV[ENV_VAR]
      Daitss::CONFIG.load ENV[ENV_VAR]
    end

    def [] key
      raise "#{key} not configured" unless super
      super
    end

  end

  CONFIG = Configuration.new
end
