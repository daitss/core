require 'yaml'

module Daitss

  CONFIG = {}

  def CONFIG.load file
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

end
