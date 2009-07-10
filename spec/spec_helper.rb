require "test_package_helper"
require "sandbox_helper"

Spec::Runner.configure do |config|

  config.before(:each) do
    $sandbox = new_sandbox
    FileUtils::mkdir $sandbox    
    
    # load the silo server
    # load the action plan
    # load the sinatra
    $test_stack = 
  end

  config.after(:each) do
    $test_stack.kill
    FileUtils::rm_rf $sandbox
  end

end