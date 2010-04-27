require 'ruby-debug'

app_file = File.join File.dirname(__FILE__), *%w[.. .. app.rb]
require app_file

# Force the application name because polyglot breaks the auto-detection logic.
Sinatra::Application.app_file = app_file
Sinatra::Application.set :environment, :test

require 'spec/expectations'
require 'rack/test'
require 'webrat'

require 'daitss2'

Webrat.configure do |config|
  config.mode = :rack
end

class MyWorld
  include Rack::Test::Methods
  include Webrat::Methods
  include Webrat::Matchers

  Webrat::Methods.delegate_to_session :response_code, :response_body

  def app
    Sinatra::Application
  end

  def sip name
    File.join File.dirname(__FILE__), '..', 'fixtures', name
  end

end

World{MyWorld.new}


Before do
  DataMapper.setup :default, Daitss::CONFIG['database-url']
  DataMapper.auto_migrate!

  a = Account.new(
    :name => 'The Test Account',
    :code => 'ACT'
  )

  o = Operator.new(
    :description => "operator",
    :active_start_date => Time.at(0),
    :active_end_date => Time.now + (86400 * 365),
    :identifier => 'operator',
    :first_name => "Op",
    :last_name => "Perator",
    :email => "operator@ufl.edu",
    :phone => "666-6666",
    :address => "FCLA"
  )

  k = AuthenticationKey.new :auth_key => Digest::SHA1.hexdigest('operator')
  o.authentication_key = k

  p = Project.new(
    :name => 'The Test Project',
    :code => 'PRJ'
  )

  a.operations_agents << o
  a.projects << p
  a.save or raise "could not save account"
end
