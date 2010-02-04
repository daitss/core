require "config"

# configuration for the test stack
TEST_STACK_CONFIG_FILE = File.join File.dirname(__FILE__), '..', 'config', 'teststack.yml'
CONFIG::load TEST_STACK_CONFIG_FILE
STATUS_ECHO_URL = 'http://localhost:7000/statusecho'

# place to put stored copies
$silo_sandbox='/tmp/silo_sandbox'
