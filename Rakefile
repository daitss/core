require 'rubygems'
require 'bundler/setup'

require 'rake'
require 'semver'

$LOAD_PATH.unshift File.join(File.dirname(__FILE__), 'lib')

require 'daitss/archive'
require 'daitss/db'
require 'daitss/model/aip'

include Daitss

namespace :db do

  task :setup do
    Archive.instance.setup_db :log => true
  end
  
  desc 'migrate the database'
  task :migrate => [:setup] do
    STDERR.puts "db:migrate has been disabled"
    #archive.setup_db :log => true
    #archive.init_db
  end

  desc 'upgrade the database'
  task :upgrade => [:setup] do
    archive.setup_db :log => true
    DataMapper.auto_upgrade!
    DataMapper.repository(:default).adapter.execute("ALTER TABLE severe_elements ALTER target TYPE character varying(255)")
    DataMapper.repository(:default).adapter.execute("ALTER TABLE severe_elements ALTER ikey TYPE character varying(255)")
  end

  desc 'insert initial data into database'
  task :initial_data => [:setup] do
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
