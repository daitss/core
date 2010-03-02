require "daitss/config"

# configuration for the test stack
raise "CONFIG environment variable is not set" unless ENV["CONFIG"]
Daitss::CONFIG::load ENV["CONFIG"]
STATUS_ECHO_URL = 'http://localhost:7000/statusecho'

def override_service key, code
  old_url = Daitss::CONFIG[key]
  Daitss::CONFIG[key] = "#{STATUS_ECHO_URL}/#{code}"
  yield
  Daitss::CONFIG[key] = old_url
end
