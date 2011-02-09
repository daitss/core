require 'semver'

module Daitss
  VERSION = SemVer.find(Rails.root).to_s
end

# processing directory
# everything should be a single filesystem
DATA_DIR = '/tmp/daitss'
