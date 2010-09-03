require 'rubygems'
require 'bundler/setup'

require 'rake'
require 'rake/rdoctask'
require 'ruby-debug'
require 'semver'
require 'spec/rake/spectask'

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), 'lib')

require 'daitss'
require 'daitss/archive'
require 'daitss/config'
require 'daitss/db'
require 'daitss/model/aip'

namespace :db do
  Daitss::CONFIG.load_from_env

  task :setup do
    Archive.setup_db :log => true
  end

  desc 'migrate the database'
  task :migrate => [:setup] do
    DataMapper.auto_migrate!
  end

  desc 'upgrade the database'
  task :upgrade => [:setup] do
    DataMapper.auto_upgrade!
  end

end
