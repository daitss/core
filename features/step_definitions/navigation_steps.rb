Given /^I goto "([^\"]*)"$/ do |path|
  visit path
end

When /^I choose "([^\"]*)"$/ do |name|
  choose name
end

When /^I press "([^\"]*)"$/ do |name|
  click_button name
end

When /^I click on "([^\"]*)"$/ do |link|
  click_link link
end

Then /^the response should be OK$/ do
  last_response.should be_ok
end
