require "help/test_package"
require "help/sandbox"
require "help/fs"
require "help/xmlvalidation"
require "help/schematron"
require "help/snafu"
require "help/reps"
require "help/store"
require "help/xpath"
require "help/test_stack"

Spec::Runner.configure do |config|

  config.before :all do
    # new sandbox
    $sandbox = new_sandbox
    FileUtils::mkdir $sandbox    

    # silo sandbox
    FileUtils::mkdir_p SILO_SANDBOX    

    # An in-memory Sqlite3 connection
    DataMapper.setup(:default, 'sqlite3::memory:')
    DataMapper.auto_migrate!
  end

  config.after :all do
    #FileUtils::rm_rf $sandbox
    FileUtils::rm_rf SILO_SANDBOX
    FileUtils::rm_rf File.join(File.dirname(__FILE__), '..', 'DescribeService.log')
  end
  
end
