require 'rake'
require 'rake/rdoctask'
require 'spec/rake/spectask'
require 'cucumber/rake/task'

Cucumber::Rake::Task.new

Spec::Rake::SpecTask.new do |t|
  t.libs << 'lib'
  t.libs << 'spec'
end

task :migrate do
  DataMapper.update!
end