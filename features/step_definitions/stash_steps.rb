Then /^I should see the wip in the stash bin$/ do
  last_response.should have_selector("td a", :content => last_package_id)
end

Given /^I stash it in "([^\"]*)"$/ do |bin_name|
  Given %Q(I goto "/workspace/#{last_package_id}")
  When %Q(I choose "stash")
  When %Q(I select "#{bin_name}")
  When %Q(I press "Update")
  Then 'I should be redirected'
  last_response.should be_ok
end
