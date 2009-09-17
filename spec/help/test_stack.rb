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

def test_stack
  
  Rack::Builder.new do

     use Rack::CommonLogger
     use Rack::ShowExceptions
     use Rack::Lint

     map "/validation" do
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
       run SimpleStorage::App.new(SILO_SANDBOX)
     end

  end
  
end

def nuke_silo_sandbox
  FileUtils::rm_rf SILO_SANDBOX
  FileUtils::mkdir_p SILO_SANDBOX
end

def run_test_stack
  httpd = Rack::Handler::Thin
  httpd.run test_stack, :Port => 7000
end
