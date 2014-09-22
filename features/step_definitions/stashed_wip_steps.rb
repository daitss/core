Then /^I should be at (the stashed wip|the wip|an error|the package) page$/ do |pg|

  case pg

  when "the stashed wip"
    (200..399).should include(page.status_code)
    page.should have_selector("h1:contains('stashed')")

  when "an error"
    (200..399).should_not include(page.status_code)
    page.should have_selector("p:contains('can only stash a non-running wip')")

  when "the wip"
    page.current_url.should match "/workspace/#{last_package_id}"
    (200..399).should include(page.status_code)
    page.should_not have_selector("h1:contains('stashed')")

  end

end

Given /^I click on the stashed wip$/ do
  click_link last_package_id
end
