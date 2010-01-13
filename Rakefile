require 'rake'
require 'rake/rdoctask'
require 'spec/rake/spectask'
require 'cucumber/rake/task'
require 'db/daitss2'

Cucumber::Rake::Task.new

Spec::Rake::SpecTask.new do |t|
  t.libs << 'lib'
  t.libs << 'spec'
end

task :db_migrate do
  DataMapper::auto_migrate!
end


task :db_upgrade do
  DataMapper::auto_upgrade!
end