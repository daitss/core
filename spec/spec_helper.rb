require 'daitss/config'
require 'fileutils'

require File.join(File.dirname(__FILE__), '..', 'tasks', 'test_env')

require 'data_mapper'

require "aip"
require "db/operations_agents"
require "db/operations_events"
require "daitss2"

require "help/test_stack"
require "help/test_package"
require "help/sandbox"
require "help/profile"
require "help/agreement"

SPEC_ROOT = File.dirname __FILE__

Spec::Runner.configure do |config|

  config.before :all do
    TestEnv.config
    TestEnv.mkdirs
    $sandbox = new_sandbox
    FileUtils::mkdir $sandbox

    #DataMapper::Logger.new($stdout, :debug)
    DataMapper.setup(:default, Daitss::CONFIG["database-url"])
    DataMapper.auto_migrate!
    setup_agreement
  end

  config.after :all do
    FileUtils::rm_rf $sandbox
  end

end
