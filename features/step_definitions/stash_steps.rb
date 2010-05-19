Then /^I should see the wip in the stash bin$/ do
  id = sips.last[:wip]
  last_response.should have_selector("td a:contains('#{id}')")
end
