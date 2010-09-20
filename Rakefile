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

desc 'generate tags file'
task :ctags do
  system "ctags -R --exclude=.git lib spec features views bin app.rb"
end

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

  desc 'insert initial data into database'
  task :initial_data => [:setup] do
    Archive.create_initial_data

    a = Account.new :id => 'ACT', :description => 'the description'
    p = Project.new :id => 'PRJ', :description => 'the description', :account => a
    a.save or 'cannot save ACT'
    p.save or 'cannot save PRJ'
  end

end
