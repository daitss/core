require 'daitss/config'
require 'daitss/auth'
require 'daitss/proc/wip'
require 'daitss/proc/workspace'
require 'daitss/model'
require 'daitss/db'

require 'semver'

module Daitss

  VERSION = SemVer.find(File.dirname(__FILE__)).format "v%M.%m.%p%s"

end
