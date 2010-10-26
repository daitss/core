Then /^I should be at (the stashed wip|the wip|an error|the package) page$/ do |page|

  case page

  when "the stashed wip"
    last_response.should be_ok
    last_response.should have_selector("h1:contains('stashed')")

  when "an error"
    last_response.should_not be_ok
    last_response.should have_selector("p:contains('can only stash a non-running wip')")

  when "the wip"
    last_request.url.should =~ %r'/workspace/#{last_package_id}'
    last_response.should be_ok
    last_response.should_not have_selector("h1:contains('stashed')")

  end

end

Given /^I click on the stashed wip$/ do
  click_link last_package_id
end
