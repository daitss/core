Given /^I goto its wip page$/ do
  id = sips.last[:wip]
  Given %Q(I goto "/workspace/#{id}")
end

Then /^the package should be (don't know|running|stopped|idle)$/ do |status|

  unless status == "don't know"
    last_response.should have_selector("h1:contains('#{status}')")
  end

end

