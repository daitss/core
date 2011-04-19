Given /^I am not logged in$/ do
  visit '/'
  click_link 'logout'
end

Given /^I am logged in$/ do
  visit '/login'
  fill_in('User', :with => 'root')
  fill_in('Password', :with => 'root')
  click_button 'login'
end

Given /^I am logged in as an affiliate of "([^"]*)"$/ do |account_id|
  a = Account.make :id => account_id

  u = User.make :id => 'hermes', :account => a
  u.encrypt_auth 'pw'
  u.save or raise 'cannot set pw for user'

  Given 'I am not logged in'
  visit '/login'
  fill_in('User', :with => 'hermes')
  fill_in('Password', :with => 'pw')
  click_button 'login'
end
