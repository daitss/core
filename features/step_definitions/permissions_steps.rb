Given /^I am logged in as an? "([^"]*)"$/ do |role|
  visit '/login'
  fill_in 'name', :with => role
  fill_in 'password', :with => 'pass'
  click_button 'login'
  follow_redirect!
end

When /^I log out and log in as an? "([^"]*)"$/ do |role|
  visit '/'
  click_button 'logout'

  visit '/login'
  fill_in 'name', :with => role
  fill_in 'password', :with => 'pass'
  click_button 'login'
  follow_redirect!
end

Given /^this test is pending$/ do
  pending "disabled limited resultset for affiliates, for now"
end

