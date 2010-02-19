require 'rack'

VAR_DIR = File.join File.dirname(__FILE__), '..', 'var'
SERVICES_DIR = File.join VAR_DIR, 'services'
SILO_DIR = File.join VAR_DIR, 'silo'
DB_FILE = File.join VAR_DIR, 'database.sqlite3'
DB_URL = "sqlite3://#{DB_FILE}"

REPOS = {
  'describe' => 'git://github.com/daitss/describe.git',
  'storage' => 'git://github.com/daitss/storage.git',
  'actionplan' => 'git://github.com/daitss/actionplan.git',
  'validate' => 'git://github.com/daitss/validate.git',
  'transform' => 'git://github.com/daitss/transform.git'
}

def service_stack

  unless %x{ffmpeg -version 2>&1}.lines.first =~ /FFmpeg version /
    raise "ffmpeg not found"
  end

  unless %x{gs -version}.lines.first =~ /Ghostscript [\d.]+/
    raise "ghostscript not found"
  end

  %w(describe validate actionplan transform storage).each do |service|
    service_dir = File.join SERVICES_DIR, service
    $:.unshift File.join(service_dir, 'lib')

    app_filename = case service
                   when 'describe' then 'describe'
                   when 'transform' then 'transform'
                   else 'app'
                   end

    require File.join(service_dir, app_filename)
  end

  $:.unshift File.join File.dirname(__FILE__), '..', 'lib'
  require 'statusecho'

  Rack::Builder.new do
    use Rack::CommonLogger
    use Rack::ShowExceptions
    use Rack::Lint

    map "/description" do
      run Describe.new
    end

    map "/validation" do
      run Validation::App.new
    end

    map "/actionplan" do       
      run ActionPlan::App.new
    end

    map "/transformation" do
      run Transform.new
    end

    map "/silo" do
      run SimpleStorage::App.new(SILO_DIR)
    end

    map "/statusecho" do
      run StatusEcho.new
    end

  end

end

namespace :services do

  desc "fetch the services"
  task :fetch do

    FileUtils::mkdir_p SERVICES_DIR


    Dir.chdir SERVICES_DIR do

      REPOS.each do |name, url|

        if File.exist? name
          puts "updating:\t#{name}"
          Dir.chdir(name) { %x{git pull} }
          raise "error updating #{name}" unless $? == 0
        else
          puts "fetching:\t#{name}"
          %x{git clone #{url} #{name}}
          raise "error fetching #{name}" unless $? == 0
        end

      end

    end

  end

  desc "nuke the services dir"
  task :clobber do
    FileUtils::rm_rf SERVICES_DIR
    FIleUtils::mkdir SERVICES_DIR
  end

  desc "run the service stack"
  task :run do
    stack = service_stack # RJB: this is needed here because RJB doesnt play nice yet

    # make the silo sandbox
    FileUtils::rm_rf SILO_DIR
    FileUtils::mkdir_p SILO_DIR

    # make the database sandbox
    require 'db/aip' # RJB: same rjb issue
    FileUtils::rm_rf DB_FILE
    DataMapper.setup :default, DB_URL
    DataMapper.auto_migrate!

    # run the test stack
    httpd = Rack::Handler::Thin
    httpd.run stack, :Port => 7000
  end

end
