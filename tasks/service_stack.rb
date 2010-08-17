require 'daitss/db/ops/aip'
require 'daitss/db/ops/operations_agents'
require 'daitss/db/ops/operations_events'

require 'test_env'

namespace :services do

  desc "fetch the services"
  task :fetch do
    include TestEnv
    ss = SERVICES.select &:running?
    raise "some services still running" unless ss.empty?

    SERVICES.each do |s|

      if s.checked_out?
        puts "fetching: #{s.name}"
        s.fetch(s.name == 'statusecho')
      else
        puts "updating: #{s.name}"
        s.clone(s.name == 'statusecho')
      end

      s.bundle unless s.name == 'statusecho'
    end

  end

  desc "stop the service stack"
  task :stop do
    TestEnv::SERVICES.each &:stop
  end

  desc "start the service stack"
  task :start do
    TestEnv.config
    TestEnv.mkdirs
    DataMapper.setup :default, Daitss::CONFIG['database-url']

    TestEnv::SERVICES.each_with_index do |s,ix|
      next if %w(request boss).include? s.name
      puts "starting #{s.name}"
      s.start(TestEnv::BASE_PORT + ix)
    end

  end

  desc "nuke the service stack installation dir"
  task :clobber do
    include TestEnv

    FileUtils::rm_rf VAR_DIR

    [ SERVICES_DIR, LOG_DIR, PID_DIR, SILO_DIR, WORKSPACE_DIR, STASHSPACE_DIR].each do |d|
      FileUtils::mkdir_p d
    end

  end

  desc "show the configuration used by specs"
  task :config do
    TestEnv.config
    puts YAML.dump(Daitss::CONFIG)
  end

end
