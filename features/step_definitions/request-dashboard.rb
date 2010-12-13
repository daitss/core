Then /^I should see a ([^"]*) request for the package$/ do |type|
  ieid = File.basename last_package
  last_response.should have_selector("#list table tr td", :content => type)
  last_response.should have_selector("#list table tr td", :content => ieid)
end

When /^I select "([^\"]*)" from "([^\"]*)" filter$/ do |selection, filter|
  select selection, :from => filter
end


Then /^I should not see a ([^"]*) request$/ do |type|
  last_response.should_not have_selector("#list table tr td", :content => type)
end

