Then /^it should have an "([^"]*)" event$/ do |name|
  e = Package.get(last_package_id).events.first :name => name
  e.should_not be_nil
end

Then /^it should have an "([^"]*)" event with note "([^"]*)"$/ do |name, note|
  e = Package.get(last_package_id).events.first :name => name, :notes => note
  e.should_not be_nil
end

Given /^"([^"]*)" is archived$/ do |sip|
  wip = submit sip
  wip.spawn
  sleep 0.2 while wip.running?
  wip.should_not be_dead
  wip.should_not be_snafu
  packages << "/package/#{wip.id}"
  visit last_package
end

When /^I wait for the "([^"]*)" to finish$/ do |task|
  r = Daitss::Request.first :package_id => last_package_id, :type => task.to_sym
  r.dispatch
  wip = r.package.wip
  wip.spawn
  sleep 0.5 while wip.running?
  wip.should_not be_dead
  wip.should_not be_snafu
end

When /^I wait for "([^"]*)" seconds$/ do |n|
  sleep n.to_f
end
