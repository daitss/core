lib_dir = File.join File.dirname(__FILE__), 'lib'
$:.unshift lib_dir

require 'daitss/config'
Daitss::CONFIG.load_from_env

require 'cucumber/rake/task'
require 'rake'
require 'rake/rdoctask'
require 'ruby-debug'
require 'semver'
require 'spec/rake/spectask'

Cucumber::Rake::Task.new do |t|
  t.cucumber_opts = "--format pretty"
end

tasks_dir = File.join File.dirname(__FILE__), 'tasks'
require File.join(tasks_dir, "service_stack")
require File.join(tasks_dir, "database")
