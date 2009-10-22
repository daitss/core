require "config"

# configuration for the test stack
TEST_STACK_CONFIG_FILE = File.join File.dirname(__FILE__), '..', 'config', 'teststack.yml'
Config::load TEST_STACK_CONFIG_FILE

# place to put stored copies
$silo_sandbox='/tmp/silo_sandbox'
