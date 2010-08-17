Then /^I should see the wip in the stash bin$/ do
  id = sips.last[:wip]
  last_response.should have_selector("td a:contains('#{id}')")
end

Given /^I stash it in "([^\"]*)"$/ do |bin_name|
  id = sips.last[:wip]
  Given %Q(I goto "/workspace/#{id}")
  When %Q(I choose "stash")
  When %Q(I select "#{bin_name}")
  When %Q(I press "Update")
  last_response.should be_ok
end

