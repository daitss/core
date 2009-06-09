gem 'rack-test', '~>0.3.0'
require 'rack/test'

gem 'webrat', '~>0.4.2'
require 'webrat'

require 'spec/expectations'

$:.unshift File.join(File.dirname(__FILE__), '..', '..', 'lib')
require 'aip'

# ride em out!
World do

  def package_instance name
    prototype = File.join File.dirname(__FILE__), 'packages', name
    FileUtils::cp_r prototype, $sandbox
    File.join $sandbox, name
  end

  def app

    Rack::Builder.new do

      # validation service
      $:.unshift File.join('..', 'validate-service', 'lib')
      require File.join('..', 'validate-service', 'server')
      map('/validation') { run Validation }
    end

  end

  include Rack::Test::Methods
  include Webrat::Methods
  include Webrat::Matchers
end

Before do

  # make a new sandbox
  tf = Tempfile.new 'sandbox'
  $sandbox = tf.path
  tf.close!    
  
  FileUtils::mkdir $sandbox
end

After do
  FileUtils::rm_rf $sandbox
end
