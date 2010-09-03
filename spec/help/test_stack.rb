def override_service key, code
  old_url = Daitss::CONFIG[key]
  Daitss::CONFIG[key] = "#{Daitss::CONFIG['statusecho']}/#{code}"
  yield
  Daitss::CONFIG[key] = old_url
end
