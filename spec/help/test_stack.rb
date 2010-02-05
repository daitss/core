require "config"

# configuration for the test stack
TEST_STACK_CONFIG_FILE = File.join File.dirname(__FILE__), '..', 'config', 'teststack.yml'
CONFIG::load TEST_STACK_CONFIG_FILE
STATUS_ECHO_URL = 'http://localhost:7000/statusecho'

def override_service key, code
  old_url = CONFIG[key]
  CONFIG[key] = "#{STATUS_ECHO_URL}/#{code}"
  yield
  CONFIG[key] = old_url
end

# place to put stored copies
$silo_sandbox='/tmp/silo_sandbox'
