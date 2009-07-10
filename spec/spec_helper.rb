require "test_package_helper"
require "sandbox_helper"

Spec::Runner.configure do |config|

  config.before(:each) do
    $sandbox = new_sandbox
    FileUtils::mkdir $sandbox    
  end

  config.after(:each) do
    #FileUtils::rm_rf $sandbox
    puts $sandbox
  end

end