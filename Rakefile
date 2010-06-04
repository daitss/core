require 'rake'
require 'rake/rdoctask'
require 'ruby-debug'
require 'semver'
require 'spec/rake/spectask'

lib_dir = File.join File.dirname(__FILE__), 'lib'
$:.unshift lib_dir

tasks_dir = File.join File.dirname(__FILE__), 'tasks'
$:.unshift tasks_dir

require 'service_stack'
require 'database'

#require 'cucumber/rake/task'
#Cucumber::Rake::Task.new do |t|
  #t.cucumber_opts = "--format pretty"
#end
