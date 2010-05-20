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

Then /^the response should be (NG|OK)$/ do |condition|

  case condition
  when 'OK' then last_response.should be_ok
  when 'NG' then last_response.should_not be_ok
  end

end

Then /^the response contains "([^\"]*)"$/ do |blurb|
  last_response.should contain(blurb)
end

Given /^I fill in "([^\"]*)" with "([^\"]*)"$/ do |field, value|
  fill_in field, :with => value
end
