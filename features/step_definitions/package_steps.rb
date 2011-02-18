Given /^a package "([^"]*)" in "([^"]*)\/([^"]*)"$/ do |id, account_id, project_id|
  prj = Project.get project_id, account_id
  Package.make :id => id, :project => prj, :sip => Sip.make_unsaved
end
