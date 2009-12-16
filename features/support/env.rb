require 'spec/expectations'

$:.unshift File.join(File.dirname(__FILE__), '..', '..', 'lib')
require 'aip'

$:.unshift File.join(File.dirname(__FILE__), '..', '..', 'spec')
require "help/sandbox"
require "help/test_package"
require "help/test_stack"
require "help/fs"

# Sqlite3 connection
DataMapper.setup(:default, CONFIG["database-uri"])
DataMapper.auto_migrate!

at_exit do
  FileUtils::rm_rf URI.parse(CONFIG["database-uri"]).path
end

Before do
  $sandbox = new_sandbox
  FileUtils::mkdir $sandbox
  ENV['WORKSPACE'] = $sandbox
  
  # silo sandbox
  FileUtils::mkdir_p $silo_sandbox

  $cleanup = []
end

After do
  FileUtils::rm_rf $sandbox
  FileUtils::rm_rf $silo_sandbox

  $cleanup.each do |dir_to_clean|
    FileUtils::rm_rf dir_to_clean
  end
end
