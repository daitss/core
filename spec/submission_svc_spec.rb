require 'submission'
require 'spec'
require 'rack/test'
require 'pp'

set :environment, :test

describe "Submission Service" do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  it "returns 400 on GET" do
    get '/'

    last_response.status.should == 400
  end

  it "returns 400 on DELETE" do
    delete '/'

    last_response.status.should == 400
  end

  it "returns 400 on HEAD" do
    head '/'

    last_response.status.should == 400
  end
end
