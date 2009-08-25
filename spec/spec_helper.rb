require "help/test_package"
require "help/sandbox"
require "help/fs"
require "help/xmlvalidation"
require "help/schematron"
require "help/snafu"

Spec::Runner.configure do |config|

  config.before(:each) do
    # Make a new fs sandbox
    $sandbox = new_sandbox
    FileUtils::mkdir $sandbox    
    
    # An in-memory Sqlite3 connection
    DataMapper.setup(:default, 'sqlite3::memory:')
    DataMapper.auto_migrate!
  end

  config.after(:each) do
    #FileUtils::rm_rf $sandbox
    puts $sandbox
    FileUtils::chmod_R 0777, "/tmp/silo_sandbox"
    `rm -rf /tmp/silo_sandbox/*`
  end

end