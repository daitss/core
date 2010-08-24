require 'rack'
require 'daitss/config'
require 'daitss/db'
require 'daitss/model/aip'

namespace :db do
  DataMapper::Logger.new STDOUT, :debug
  Daitss::CONFIG.load_from_env

  desc 'setup the database'
  task :setup do
    DataMapper.setup :default, Daitss::CONFIG['database-url']
  end

  desc 'migrate the database'
  task :migrate => [:setup] do
    DataMapper::auto_migrate!
  end

  desc 'upgrade the database'
  task :upgrade => [:setup] do
    DataMapper::auto_upgrade!
  end

  desc 'migrate the aip database'
  task :aip_migrate => [:setup] do
    repository(:aipstore) { Aip.auto_migrate! }
  end

end
