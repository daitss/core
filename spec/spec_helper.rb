require "help/test_stack"
require "help/test_package"
require "help/sandbox"
require "db/aip"
require 'datamapper'

Spec::Runner.configure do |config|

  config.before :all do
    $sandbox = new_sandbox
    FileUtils::mkdir $sandbox

    CONFIG["database-uri"] = 'sqlite3::memory:'
    DataMapper.setup(:default, CONFIG["database-uri"])
    DataMapper.auto_migrate!
  end

  config.after :all do
    FileUtils::rm_rf $sandbox
  end
  
end
