require 'spec/expectations'

$:.unshift File.join(File.dirname(__FILE__), '..', '..', 'lib')
require 'aip'

$:.unshift File.join(File.dirname(__FILE__), '..', '..', 'spec')
require "help/sandbox"
require "help/test_package"
require "help/test_stack"

SILO_SANDBOX = '/tmp/silo_sandbox'

Before do
  $sandbox = new_sandbox
  FileUtils::mkdir $sandbox
  ENV['DAITSS_WORKSPACE'] = $sandbox
  
  # silo sandbox
  FileUtils::mkdir_p SILO_SANDBOX

  # Tempfile Sqlite3 connection
  SERVICE_URLS["database"] = "sqlite3:///tmp/db_sandbox"
  DataMapper.setup(:default, SERVICE_URLS["database"])
  DataMapper.auto_migrate!
end

After do
  #FileUtils::rm_rf $sandbox
  FileUtils::rm_rf SILO_SANDBOX
  FileUtils::rm_rf URI.parse(SERVICE_URLS["database"]).path
end
