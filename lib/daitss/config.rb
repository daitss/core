require 'yaml'

module Daitss

  CONFIG = {}

  def CONFIG.load file
    merge! YAML.load_file file

    # sane defaults
    CONFIG['http-timeout'] ||= 60 * 10 # 10 minutes
  end

end
