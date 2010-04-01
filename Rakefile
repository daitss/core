require 'cucumber/rake/task'
require 'rake'
require 'rake/gempackagetask'
require 'rake/rdoctask'
require 'semver'
require 'spec/rake/spectask'
require 'daitss2'
require 'db/aip'

Cucumber::Rake::Task.new do |t|
  t.cucumber_opts = "--format pretty"
end

task :db_migrate do
  DataMapper::Logger.new(STDOUT, :debug)
  DataMapper.setup(:default, 'mysql://daitss:topdrawer@localhost/daitss2')
  DataMapper::auto_migrate!
end

task :db_upgrade do
  DataMapper::Logger.new(STDOUT, :debug)
  DataMapper.setup(:default, 'mysql://daitss:topdrawer@localhost/daitss2')
  DataMapper::auto_upgrade!
end

task :aip_migrate do

  repository(:aipstore) do
    Aip.auto_migrate!
  end

end

tasks_dir = File.join File.dirname(__FILE__), 'tasks'
require File.join(tasks_dir, "service_stack")
