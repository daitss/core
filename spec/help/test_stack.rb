STATUS_ECHO_URL = 'http://localhost:7003'

def override_service key, code
  old_url = Daitss::CONFIG[key]
  Daitss::CONFIG[key] = "#{STATUS_ECHO_URL}/#{code}"
  yield
  Daitss::CONFIG[key] = old_url
end
