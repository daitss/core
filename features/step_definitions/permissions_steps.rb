Given /^I am logged in as an? "([^"]*)"$/ do |role|
  visit '/login'
  fill_in 'name', :with => role
  fill_in 'password', :with => 'pass'
  click_button 'login'
  follow_redirect!
end
