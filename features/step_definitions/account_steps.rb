Given /^an account "([^"]*)"$/ do |id|
  Account.make :id => id
end

Given /^account "([^"]*)" has a project "([^"]*)"$/ do |account_id, project_id|
  Project.make :id => project_id, :account_id => account_id
end
