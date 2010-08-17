Then /^I should be at (the stashed wip|the wip|an error|the package) page$/ do |page|

  case page

  when "the stashed wip"
    last_response.should be_ok
    id = sips.last[:wip]
    last_response.should have_selector("h1:contains('stashed')")

  when "an error"
    last_response.should_not be_ok
    last_response.should have_selector("p:contains('can only stash a non-running wip')")

  when "the wip"
    id = sips.last[:wip]
    last_request.url.should =~ %r'/workspace/#{id}'
    last_response.should be_ok
    id = sips.last[:wip]
    last_response.should_not have_selector("h1:contains('stashed')")

  when "the package"
    id = sips.last[:wip]
    last_request.url.should =~ %r'/package/#{id}'
    last_response.should be_ok

  end

end

Given /^I click on the stashed wip$/ do
  id = sips.last[:wip]
  click_link id
end
