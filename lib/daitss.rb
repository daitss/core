require 'daitss/archive'
require 'daitss/proc/wip'
require 'daitss/proc/workspace'
require 'daitss/model'
require 'daitss/db'

require 'semver'

module Daitss
  VERSION_FORMAT = "v%M.%m.%p%s"
  VERSION = SemVer.find(File.dirname(__FILE__)).format VERSION_FORMAT
end
