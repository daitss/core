require 'open3'
require 'tempfile'
require 'mongrel'

# dir of test sips
TEST_SIP_DIR = File.join 'spec', 'sips'

def test_package name
  File.join Dir.pwd, 'spec', 'packages', name
end
