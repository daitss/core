require "help/test_package"
require "help/sandbox"
require "help/fs"
require "help/xmlvalidation"
require "help/schematron"
require "help/snafu"
require "help/reps"
require "help/store"
require 'help/test_stack'

VENDOR_DIR = File.join(File.dirname(__FILE__), '..', 'vendor')

# Make it the configuration
SERVICE_URLS = {
  "actionplan" => "http://localhost:7000/actionplan/instructions",
  "validation" => "http://localhost:7000/validation/results",
  "provenance" => "http://localhost:7000/provenance",
  "description" => "http://localhost:7000/description/describe",
  "storage" => "http://localhost:7001/one/data"
}


include TestStack
Spec::Runner.configure do |config|

  config.before(:all) do
    start_sinatra
    start_storage    
  end

  config.after(:all) do
    stop_sinatra
    stop_storage    
  end

  config.before(:each) do
    # Make a new fs sandbox
    $sandbox = new_sandbox
    FileUtils::mkdir $sandbox
    
    # An in-memory Sqlite3 connection
    DataMapper.setup(:default, 'sqlite3::memory:')
    DataMapper.auto_migrate!
  end

  config.after(:each) do
    # kill the sandbox
    FileUtils::rm_rf $sandbox
    
    nuke_silo_sandbox
  end
  
end
