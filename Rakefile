require 'rake'
require 'rake/rdoctask'
require 'spec/rake/spectask'
require 'cucumber/rake/task'

Spec::Rake::SpecTask.new do |t|
  t.libs << 'lib'
  t.libs << 'spec'
  t.spec_opts << "--color"
end
 
Cucumber::Rake::Task.new do |t|
  t.cucumber_opts = "--format pretty"
end

task :default => [:spec]
