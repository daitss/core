require 'spec/expectations'

$:.unshift File.join(File.dirname(__FILE__), '..', '..', 'lib')
require 'aip'

$:.unshift File.join(File.dirname(__FILE__), '..', '..', 'spec')
require "help/sandbox"
require "help/test_package"
require "help/test_stack"

# Sqlite3 connection
DataMapper.setup(:default, Config::Service["database"])
DataMapper.auto_migrate!

at_exit do
  FileUtils::rm_rf URI.parse(Config::Service["database"]).path
end

Before do
  $sandbox = new_sandbox
  FileUtils::mkdir $sandbox
  ENV['DAITSS_WORKSPACE'] = $sandbox
  
  # silo sandbox
  FileUtils::mkdir_p $silo_sandbox
end

After do
  FileUtils::rm_rf $sandbox
  FileUtils::rm_rf $silo_sandbox
end
