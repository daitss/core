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

Given /^package "([^"]*)" is "([^"]*)" at "([^"]*)"$/ do |id, state, time|

  name = case state
         when 'archived' then 'ingest finished'
         else state
         end

  e = Event.create(:name => name, :package_id => id, :agent_id => SYSTEM_PROGRAM_ID, :timestamp => Time.parse(time))
  raise "can't save event" unless e.saved?
end

Given /^the packages in "([^"]*)":$/ do |act_prj, table|

  table.rows.each do |id, state, time|
    Given %Q{a package "#{id}" in "#{act_prj}"}
    Given %Q{package "#{id}" is "#{state}" at "#{time}"}
  end

end
