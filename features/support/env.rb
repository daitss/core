require 'rubygems'
require 'bundler/setup'
require 'daitss/archive'

require File.join(File.dirname(__FILE__), *%w[.. .. app.rb])

require 'ruby-debug'
require 'net/http'
require 'rspec'
require 'rack/test'
require 'webrat'
require 'nokogiri'

require 'daitss/model'
require 'daitss/archive'
require 'open-uri'

require 'spec_helper'

Webrat.configure { |config| config.mode = :rack }

class MyWorld
  include Rack::Test::Methods
  include Webrat::Methods
  include Webrat::Matchers

  Webrat::Methods.delegate_to_session :response_code, :response_body

  def app
    Sinatra::Application.environment = :test
    Sinatra::Application.disable :show_exceptions
    Sinatra::Application
  end

  def fixture name
    if name.include? " "
      filename = "http://www.fcla.edu/daitss-test/packages/" + URI.escape(name) #space character is handled differently
    else
      filename = "http://www.fcla.edu/daitss-test/packages/" + CGI.escape(name)
    end  
    tmpfile = @tmpdir + '/' + name
    File.open("#{tmpfile}", "wb") do |file|
      file.write open("#{filename}").read
    end
    return tmpfile
  end
  
  #remove downloaded fixture
  def rm_fixture tmpfile
    FileUtils.remove_entry_secure "#{@tmpdir}" + '/' + "#{tmpfile}" + ".zip"
  end
  
  #mk tmp dir for fixtures
  def mktmpdir
    @tmpdir = Dir.mktmpdir
  end
  
  #rm tmp dir for fixtures
  def rm_tmpdir
    FileUtils.remove_entry_secure @tmpdir
  end
    
  def packages
    @packages ||= []
  end

  def last_package
    packages.last
  end

  def last_package_id
    last_package.split('/').last
  end

  def empty_out_workspace
    ws = Daitss.archive.workspace

    ws.each do |wip|
      wip.stop if wip.running?
      FileUtils.rm_r wip.path
    end

  end

  def reload!
    visit last_request.env["PATH_INFO"]
  end

end

World do
  MyWorld.new
end

Before do
  archive = Daitss.archive
  FileUtils.rm_rf archive.data_dir
  FileUtils.mkdir_p archive.data_dir
  archive.init_data_dir
  archive.setup_db
  archive.init_db
  archive.init_seed

  # extra initial data

  a = Account.get("ACT") or raise "Project ACT not found"

  # affiliate
  aff = User.new :id => 'affiliate', :account => a
  aff.encrypt_auth('pass')
  aff.save or raise 'cannot save aff'

  # operator
  op = Operator.new :id => 'operator', :account => a
  op.encrypt_auth('pass')
  op.save or raise 'cannot save aff'

  # second operator
  op2 = Operator.new :id => 'operator2', :account => a
  op2.encrypt_auth('pass')
  op2.save or raise 'cannot save aff'

  mktmpdir

  visit '/login'
  fill_in 'name', :with => 'operator'
  fill_in 'password', :with => 'pass'
  click_button 'login'
  follow_redirect!
  last_response.should be_ok
end

After do
  visit '/'
  click_button 'logout'
  rm_tmpdir
  
  Daitss.archive.workspace.each do |w|
    w.kill if w.running?
    FileUtils.rm_rf w.path
  end
end
