Then /^I should see the wip in the stash bin$/ do
  page.should have_selector("td a", :text => last_package_id)
end

Given /^I stash it in "([^\"]*)"$/ do |bin_name|
  step %Q(I goto "/workspace/#{last_package_id}")
  step %Q(I choose "stash")
  step %Q(I select "#{bin_name}")
  step %Q(I press "Update")
  step 'I should be redirected'
  (200..399).should include(page.status_code)
end

Then /^I should see no stashed packages$/ do
  page.should_not have_selector("tr:contains('package')")
end
