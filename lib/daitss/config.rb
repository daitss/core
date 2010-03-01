require 'yaml'

module Daitss

  CONFIG = {}

  def CONFIG.load file
    merge! YAML.load open(file) { |io| io.read }

    # sane defaults
    CONFIG['http-timeout'] ||= 60 * 10 # 10 minutes
  end

end
