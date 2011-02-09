Given /^I am not logged in$/ do
  visit '/'
  click_link 'logout root'
end

Given /^I am logged in$/ do
  visit '/login'
  fill_in('User', :with => 'root')
  fill_in('Password', :with => 'root')
  click_button 'login'
end
