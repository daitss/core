Then /^it should have an "([^"]*)" event$/ do |name|
  e = Package.get(last_package_id).events.first :name => name
  e.should_not be_nil
end
