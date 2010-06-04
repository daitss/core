require 'aip'
require 'db/operations_agents'
require 'db/operations_events'

require 'service'
SERVICES = %w(actionplan describe request statusecho storage submission transform viruscheck).map { |s| Service.new s }

namespace :services do

  desc "fetch the services"
  task :fetch do
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

      s.bundle
    end

  end

  desc "stop the service stack"
  task :stop do
    SERVICES.each &:stop
  end

  desc "start the service stack"
  task :start do
    DataMapper.setup :default, Daitss::CONFIG['database-url']
    SERVICES.each_with_index { |s,ix| s.start(BASE_PORT + ix) }
  end

  desc "nuke the services dir"
  task :clobber do

    [ SERVICES_DIR, LOG_DIR, PID_DIR, SILO_DIR].each do |d|
      FileUtils::rm_rf d
      FileUtils::mkdir_p d
    end

  end

end
