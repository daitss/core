require "help/test_stack"
require "help/test_package"
require "help/sandbox"

require 'datamapper'

Spec::Runner.configure do |config|

  config.before :all do
    # new sandboxes
    $sandbox = new_sandbox
    FileUtils::mkdir $sandbox
    FileUtils::mkdir_p $silo_sandbox

    # An in-memory Sqlite3 connection
    CONFIG["database-uri"] = 'sqlite3::memory:'
    DataMapper.setup(:default, CONFIG["database-uri"])
    DataMapper.auto_migrate!
  end

  config.after :all do
    FileUtils::rm_rf $sandbox
    FileUtils::rm_rf $silo_sandbox
    FileUtils::rm_rf File.join(File.dirname(__FILE__), '..', 'DescribeService.log')
  end
  
end
