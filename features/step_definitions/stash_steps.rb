Then /^I should see the wip in the stash bin$/ do
  last_response.should have_selector("td a", :content => last_package_id)
end

Given /^I stash it in "([^\"]*)"$/ do |bin_name|
  step %Q(I goto "/workspace/#{last_package_id}")
  step %Q(I choose "stash")
  step %Q(I select "#{bin_name}")
  step %Q(I press "Update")
  step 'I should be redirected'
  last_response.should be_ok
end

Then /^I should see no stashed packages$/ do
  last_response.should_not have_selector("tr:contains('package')")
end
