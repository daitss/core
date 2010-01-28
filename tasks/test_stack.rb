require 'rack'
require 'db/aip'

# echo the status back to the requestor
require 'sinatra/base'

class StatusEcho < Sinatra::Base

  get '/code/:code' do |code|

    if code.to_i == 200
      'all good'
    else
      halt code, 'you asked for it'
    end

  end

end

TS_DIR = File.join File.dirname(__FILE__), '..', '.test-stack'

def test_stack

  ENV["PATH"] = "/Applications/ffmpegX.app/Contents/Resources:#{ENV["PATH"]}"

  # access the services code
  %w(describe validate actionplan transform storage).each do |service|
    service_dir = File.join TS_DIR, service
    $:.unshift File.join(service_dir, 'lib')

    app_filename = case service
                   when 'describe' then 'describe'
                   when 'transform' then 'transform'
                   else 'app'
                   end

    require File.join(service_dir, app_filename)
  end

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
      run SimpleStorage::App.new($silo_sandbox)
    end

  end

end

def nuke_silo_sandbox
  FileUtils::rm_rf $silo_sandbox
  FileUtils::mkdir_p $silo_sandbox
end

def run_test_stack
  httpd = Rack::Handler::Thin
  httpd.run test_stack, :Port => 7000
end


namespace :ts do

  desc "fetch the test stack"
  task :fetch do

    FileUtils::mkdir_p TS_DIR

    vc_urls = {
      'describe' => 'git://github.com/daitss/describe.git',
      'storage' => 'git://github.com/daitss/storage.git',
      'actionplan' => 'git://github.com/daitss/actionplan.git',
      'validate' => 'git://github.com/daitss/validate.git',
      'transform' => 'git://github.com/daitss/transform.git'
    }

    Dir.chdir TS_DIR do

      vc_urls.each do |name, url|

        if File.exist? name
          puts "updating:\t#{name}"
          Dir.chdir(name) { `git pull` }
          raise "error updating #{name}" unless $? == 0
        else
          puts "fetching:\t#{name}"
          `git clone #{url} #{name}`
          raise "error fetching #{name}" unless $? == 0
        end

      end

    end

  end

  desc "nuke the test stack"
  task :clobber do
    FileUtils::rm_rf TS_DIR
  end

  desc "run the test stack"
  task :run do

    # make the database sandbox
    $db_sandbox='sqlite3:///tmp/db_sandbox'
    DataMapper.setup(:default, $db_sandbox)
    DataMapper.auto_migrate!

    # make the silo sandbox
    $silo_sandbox='/tmp/silo_sandbox'
    nuke_silo_sandbox
    FileUtils::mkdir_p $silo_sandbox

    # run the test stack
    run_test_stack
  end

end
