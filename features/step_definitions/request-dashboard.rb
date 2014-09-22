Then /^I should see a ([^"]*) request for the package$/ do |type|
  ieid = File.basename last_package
  page.should have_selector("#list table tr td", :text => type)
  page.should have_selector("#list table tr td", :text => ieid)
end

When /^I select "([^\"]*)" from "([^\"]*)" filter$/ do |selection, filter|
  select selection, :from => filter
end


Then /^I should not see a ([^"]*) request$/ do |type|
  page.should_not have_selector("#list table tr td", :text => type)
end

