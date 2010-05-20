Then /^I should be at (the stashed wip|an error)$/ do |page|

  case page

  when "the stashed wip"
    last_response.should be_ok
    id = sips.last[:wip]
    last_response.should have_selector("h1:contains('stashed')")

  when "an error"
    last_response.should_not be_ok
    last_response.should have_selector("p:contains('can only stash a non-running wip')")

  end

end
