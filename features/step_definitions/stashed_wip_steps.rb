Then /^I should be at (the stashed wip|an error) page$/ do |page|

  if page == "the stashed wip"
    id = sips.last[:wip]
    last_response.should have_selector("h1:contains('stashed')")
  elsif page == "an error"
    last_response.should have_selector("p:contains('can only stash a non-running wip')")
  end

end
