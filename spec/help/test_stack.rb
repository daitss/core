require "daitss/config"

# configuration for the test stack
TEST_STACK_CONFIG_FILE = "/Users/franco/Code/daitss/meta/config.yml"
Daitss::CONFIG::load TEST_STACK_CONFIG_FILE
STATUS_ECHO_URL = 'http://localhost:7000/statusecho'

def override_service key, code
  old_url = Daitss::CONFIG[key]
  Daitss::CONFIG[key] = "#{STATUS_ECHO_URL}/#{code}"
  yield
  Daitss::CONFIG[key] = old_url
end
