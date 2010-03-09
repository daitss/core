require 'datamapper'
require 'fileutils'

require "db/aip"
require 'daitss/config'

require "help/test_stack"
require "help/test_package"
require "help/sandbox"

raise 'CONFIG not specified' unless ENV['CONFIG']
Daitss::CONFIG.load ENV['CONFIG']
Daitss::CONFIG["database-uri"] = 'sqlite3::memory:'


Spec::Runner.configure do |config|

  config.before :all do
    $sandbox = new_sandbox
    FileUtils::mkdir $sandbox

    DataMapper.setup(:default, Daitss::CONFIG["database-uri"])
    DataMapper.auto_migrate!
  end

  config.after :all do
    FileUtils::rm_rf $sandbox
  end

end
