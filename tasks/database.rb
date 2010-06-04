require 'rack'
require 'daitss/config'
require 'aip'

namespace :db do

  desc 'setup the database'
  task :setup do
    require 'daitss2'
    DataMapper::Logger.new STDOUT, :debug
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
