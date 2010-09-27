require 'rubygems'
require 'bundler/setup'
require 'daitss/archive'

app_file = File.join File.dirname(__FILE__), *%w[.. .. app.rb]
require app_file

# Force the application name because polyglot breaks the auto-detection logic.
Sinatra::Application.app_file = app_file
Sinatra::Application.set :environment, :test

require 'ruby-debug'
require 'net/http'
require 'spec/expectations'
require 'rack/test'
require 'webrat'
require 'nokogiri'

require 'daitss/model'
require 'daitss/archive'

Webrat.configure { |config| config.mode = :rack }

class MyWorld
  include Rack::Test::Methods
  include Webrat::Methods
  include Webrat::Matchers

  Webrat::Methods.delegate_to_session :response_code, :response_body

  def app
    Sinatra::Application
  end

  def fixture name
    File.join File.dirname(__FILE__), '..', 'fixtures', name
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
    ws = Daitss::Archive.instance.workspace

    ws.each do |wip|
      wip.stop if wip.running?
      FileUtils.rm_r wip.path
    end

  end

end

World { MyWorld.new }

Before do
  archive = Daitss::Archive.instance
  FileUtils.rm_rf archive.data_dir
  FileUtils.mkdir archive.data_dir
  archive.init_data_dir
  archive.setup_db
  archive.init_db
  archive.create_initial_data

  # extra initial data
  a = Account.new :id => 'ACT', :description => 'the description'
  pd = Project.new :id => 'default', :description => 'the default description', :account => a
  p = Project.new :id => 'PRJ', :description => 'the description', :account => a
  a.save or 'cannot save ACT'
  pd.save or 'cannot save ACT/default'
  p.save or 'cannot save PRJ'
end

After do

  Daitss::Archive.instance.workspace.each do |w|
    w.kill if w.running?
    FileUtils.rm_rf w.path
  end

end
