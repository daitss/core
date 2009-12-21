require 'rack'

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

TS_DIR = File.join File.dirname(__FILE__), '..', 'test-stack'

def test_stack

  # validation & provenance
  validation_dir = File.join TS_DIR, 'validation'
  $:.unshift File.join(validation_dir, 'lib')
  require File.join(validation_dir, 'validation')
  require File.join(validation_dir, 'provenance')

  # description
  description_dir = File.join TS_DIR, 'description'
  $:.unshift File.join(description_dir, 'lib')
  require File.join(description_dir, 'describe')

  # actionplan
  actionplan_dir = File.join TS_DIR, 'actionplan'
  $:.unshift File.join(actionplan_dir, 'lib')
  require File.join(actionplan_dir, 'app')

  # transformation
  ENV["PATH"] = "/Applications/ffmpegX.app/Contents/Resources:#{ENV["PATH"]}"
  transformation_dir = File.join TS_DIR, 'transformation'
  $:.unshift File.join(transformation_dir, 'lib')
  require File.join(transformation_dir, 'transform')

  # storage
  storage_dir = File.join TS_DIR, 'simplestorage'
  $:.unshift File.join(storage_dir, 'lib')
  require File.join(storage_dir, 'app')

  
  Rack::Builder.new do
    # TODO take paths from CONFIG
    

    map "/validation" do
      use Rack::CommonLogger
      use Rack::ShowExceptions
      use Rack::Lint
      run Validation.new
    end

    map "/provenance" do
      run Provenance.new
    end

    map "/description" do
      run Describe.new
    end

    map "/actionplan" do       
      run ActionPlanD.new
    end

    map "/transformation" do
      run Transform.new
    end

    map "/silo" do
      use Rack::ShowExceptions
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

# test stack dir

namespace :ts do
  
  desc "fetch the test stack"
  task :fetch do

    FileUtils::mkdir_p TS_DIR

    vc_urls = {
      'description' => "git://github.com/cchou/describe.git",
      'simplestorage' => "ssh://retsina.fcla.edu/var/git/simplestorage.git",
      'actionplan' => "ssh://retsina.fcla.edu/var/git/actionplan.git",
      'validation' => "svn://tupelo.fcla.edu/shades/validate-service",
      'transformation' => "svn://tupelo.fcla.edu/daitss2/transform/trunk"
    }

    Dir.chdir TS_DIR do
      
      vc_urls.each do |name, url|
        
        if File.exist? name
          puts "updating:\t#{name}"
          
          if url =~ %r{^svn://}
            Dir.chdir(name) { `svn up` }
          else
            Dir.chdir(name) { `git pull` }
          end
          
          raise "error updating #{name}" unless $? == 0
        else
          puts "fetch:\t#{name}"
          
          if url =~ %r{^svn://}
            `svn co #{url} #{name}`  
          else
            `git clone #{url} #{name}`
          end

          raise "error retrieving #{name}" unless $? == 0
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
    $:.unshift '/Users/franco/Code/d2aip/lib'
    require 'aip'
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
