Given /^I am logged in as an? "([^"]*)"$/ do |role|
  visit '/login'
  fill_in 'name', :with => role
  fill_in 'password', :with => 'pass'
  click_button 'login'
end

When /^I log out and log in as an? "([^"]*)"$/ do |role|
  visit '/'
  click_button 'logout'

  visit '/login'
  fill_in 'name', :with => role
  fill_in 'password', :with => 'pass'
  click_button 'login'
end

Given /^this test is pending$/ do
  pending "this test is pending"
end

