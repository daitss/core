Given /^I goto its wip page$/ do
  id = sips.last[:wip]
  Given %Q(I goto "/workspace/#{id}")
end

Then /^the package should be (don't know|running|stopped|idle)$/ do |status|

  unless status == "don't know"
    last_response.should have_selector("h1:contains('#{status}')")
  end

end

Then /^I should see the progress section$/ do
  last_response.should have_selector("h2:contains('progress')")
end

Then /^in the progress section I should see a field for "([^\"]*)"$/ do |field|
  last_response.should have_selector("th:contains('#{field}')")
end
