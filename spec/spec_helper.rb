require 'daitss/config'
require 'fileutils'

test_config = File.join File.dirname(__FILE__), '..', 'tasks', 'test-config.yml'
Daitss::CONFIG.load test_config
[ Daitss::CONFIG['workspace'], Daitss::CONFIG['stashspace'] ].each { |d| FileUtils.mkdir_p d unless File.exist? d }

require 'datamapper'

require "aip"
require "db/operations_agents"
require "db/operations_events"
require "daitss2"

require "help/test_stack"
require "help/test_package"
require "help/sandbox"
require "help/profile"

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
