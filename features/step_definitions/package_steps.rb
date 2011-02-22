Given /^a package "([^"]*)" in "([^"]*)\/([^"]*)"$/ do |id, account_id, project_id|
  prj = Project.get project_id, account_id
  Package.make :id => id, :project => prj, :sip => Sip.make_unsaved
end

Given /^project "([^"]*)\/([^"]*)" has (\d+) arbitrary packages$/ do |account_id, project_id, count|

  count.to_i.times do
    prj = Project.get project_id, account_id
    Package.make :project => prj, :sip => Sip.make_unsaved
  end

end
