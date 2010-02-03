require 'uuid'
require 'datamapper'
require 'fileutils'
require 'tempfile'
require 'wip/create'

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

def submit workspace, sip_name
  sip_path = File.join SIP_DIR, sip_name
  sip = Sip.new sip_path

  wip_id = UG.generate :compact
  path = File.join workspace.path, wip_id
  uri = "#{URI_PREFIX}/#{wip_id}"
  wip = Wip::make_from_sip path, uri, sip
  wip.tags['task'] = 'ingest'
  wip
end

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
