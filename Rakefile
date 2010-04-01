require 'cucumber/rake/task'
require 'rake'
require 'rake/rdoctask'
require 'semver'
require 'spec/rake/spectask'
require 'daitss/config'
require 'ruby-debug'

raise "CONFIG not set" unless ENV['CONFIG']
Daitss::CONFIG.load ENV['CONFIG']

Cucumber::Rake::Task.new do |t|
  t.cucumber_opts = "--format pretty"
end

tasks_dir = File.join File.dirname(__FILE__), 'tasks'
require File.join(tasks_dir, "service_stack")
require File.join(tasks_dir, "database")
