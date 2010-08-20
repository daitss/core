require 'daitss/config'
require 'fileutils'

require File.join(File.dirname(__FILE__), '..', 'tasks', 'test_env')

require 'data_mapper'

require "daitss/db/ops/aip"
require "daitss/db/ops/operations_agents"
require "daitss/db/ops/operations_events"
require "daitss/db/fast"

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
    $sandbox = Dir.mktmpdir

    #DataMapper::Logger.new($stdout, :debug)
    DataMapper.setup(:default, Daitss::CONFIG["database-url"])
    DataMapper.auto_migrate!
    setup_agreement

    $cleanup = [$sandbox]
  end

  config.after :all do
    $cleanup.each { |x| FileUtils::rm_rf x }
  end

end
