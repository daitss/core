require 'spec/expectations'

$:.unshift File.join(File.dirname(__FILE__), '..', '..', 'lib')
require 'aip'

$:.unshift File.join(File.dirname(__FILE__), '..', '..', 'spec')
require "sandbox_helper"
require "test_package_helper"

Before do
  $sandbox = new_sandbox
  FileUtils::mkdir $sandbox
  ENV['DAITSS_WORKSPACE'] = $sandbox
end

After do
  #FileUtils::rm_rf $sandbox
end
