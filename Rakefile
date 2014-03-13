# Some of these targest must be executed as
#
#     bundle exec rake <target>
#
# esp. :db and :rspec.
# 


require 'rubygems'

require 'rake'
require 'semver'

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), 'lib')

namespace :db do


  task :setup do
    require 'bundler/setup'
    require 'daitss/archive'
    require 'daitss/db'
    require 'daitss/model/aip'

    include Daitss

    Archive.instance.setup_db :log => true
  end
  
  desc 'migrate the database'
  task :migrate => [:setup] do
    require 'bundler/setup'
    require 'daitss/archive'
    require 'daitss/db'
    require 'daitss/model/aip'

    include Daitss

    archive.setup_db :log => true
    archive.init_db
   end

  desc 'upgrade the database'
  task :upgrade => [:setup] do
    require 'bundler/setup'
    require 'daitss/archive'
    require 'daitss/db'
    require 'daitss/model/aip'

    include Daitss

    archive.setup_db :log => true
    DataMapper.auto_upgrade!
   end

  desc 'insert initial data into database'
  task :initial_data => [:setup] do
    require 'daitss/archive'
    require 'daitss/db'
    require 'daitss/model/aip'
    require 'bundler/setup'

    include Daitss
    
    archive.setup_db :log => true
    Archive.create_initial_data

    a = Account.new :id => 'ACT', :description => 'the description'
    p = Project.new :id => 'PRJ', :description => 'the description', :account => a
    a.save or 'cannot save ACT'
    p.save or 'cannot save PRJ'
  end

end

require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new do |t|
  t.rspec_opts = ["-c", "-f Fuubar", "--fail-fast", "-r ./spec/spec_helper.rb"]
  t.pattern = 'spec/**/*_spec.rb'
end

require 'cucumber/rake/task'

Cucumber::Rake::Task.new(:features) do |t|
  t.cucumber_opts = "features --format progress"
end


HOME    = File.expand_path(File.dirname(__FILE__))

# map local users to server users

if ENV["USER"] == "Carol"
  user = "cchou"
else
  user = ENV["USER"]
end

desc "Hit the restart button for apache/passenger, pow servers"
task :restart do
  sh "touch #{HOME}/tmp/restart.txt"
end

desc "deploy to darchive's production site (core.fda.fcla.edu)"
task :darchive do
    sh "cap deploy -S target=darchive.fcla.edu:/opt/web-services/sites/core -S who=#{user}:#{user}"
end

desc "deploy to development site (core.retsina.fcla.edu)"
task :retsina do
    sh "cap deploy -S target=retsina.fcla.edu:/opt/web-services/sites/core -S who=daitss:daitss"
end

desc "deploy to development site (core.marsala.fcla.edu)"
task :marsala do
	    sh "cap deploy -S target=marsala.fcla.edu:/opt/web-services/sites/core -S who=#{user}:#{user}"
end

desc "deploy to ripple's test site (core.ripple.fcla.edu)"
task :ripple do
    sh "cap deploy -S target=ripple.fcla.edu:/opt/web-services/sites/core -S who=#{user}:#{user} branch=interim"
end

desc "deploy to tarchive's coop (core.tarchive.fcla.edu?)"
task :tarchive_coop do
    sh "cap deploy -S target=tarchive.fcla.edu:/opt/web-services/sites/coop/core -S who=#{user}:#{user}"
end

defaults = [:restart]

task :default => defaults
