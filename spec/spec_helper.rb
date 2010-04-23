require 'datamapper'
require 'fileutils'

require "aip"
require "db/operations_agents"
require "db/operations_events"
require "daitss2"
require 'daitss/config'

require "help/test_stack"
require "help/test_package"
require "help/sandbox"

raise 'CONFIG not specified' unless ENV['CONFIG']
Daitss::CONFIG.load ENV['CONFIG']
Daitss::CONFIG["database-url"] = 'sqlite3::memory:'


Spec::Runner.configure do |config|

  config.before :all do
    $sandbox = new_sandbox
    FileUtils::mkdir $sandbox

    DataMapper.setup(:default, Daitss::CONFIG["database-url"])
    DataMapper.auto_migrate!
  end

  config.after :all do
    FileUtils::rm_rf $sandbox
  end

end
