require 'daitss/config'
require 'fileutils'

require File.join(File.dirname(__FILE__), '..', 'tasks', 'test_env')

require 'data_mapper'

require "daitss/model/aip"
require "daitss/model/agent"
require "daitss/model/event"
require "daitss/db"

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
    $cleanup = [$sandbox]

    Archive.setup_db

    DataMapper.auto_migrate!
    setup_agreement
  end

  config.after :all do
    $cleanup.each { |x| FileUtils::rm_rf x }
  end

end
