require 'uuid'
require 'datamapper'
require 'fileutils'
require 'tempfile'

UG = UUID.new

def new_sandbox
  tf = Tempfile.new 'sandbox'
  path = tf.path
  tf.close!

  if block_given?
    FileUtils::mkdir_p path
    yield path
    FileUtils::rm_rf path
  else
    path
  end

end

SIP_DIR = File.join File.dirname(__FILE__), 'sips'

URI_PREFIX = "test:/"

Spec::Runner.configure do |config|

  config.before :all do
    $sandbox = new_sandbox
    FileUtils::mkdir_p $sandbox

    # An in-memory Sqlite3 connection
    DataMapper.setup :default, 'sqlite3::memory:'
    DataMapper.auto_migrate!
  end

  config.after :all do
    FileUtils::rm_rf $sandbox
  end
  
end
