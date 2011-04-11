Given /^an account "([^"]*)"$/ do |id|
  prj = Project.new :id => DEFAULT_PROJECT_ID, :description => 'default project'
  Account.make :id => id, :projects => [prj]
end

Given /^account "([^"]*)" has a project "([^"]*)"$/ do |account_id, project_id|
  Project.make :id => project_id, :account_id => account_id
end
