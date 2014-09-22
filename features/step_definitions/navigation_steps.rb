Given /^I goto "([^\"]*)"$/ do |path|
  visit path
end

When /^I choose "([^\"]*)"$/ do |name|
  choose name
end

When /^I press "([^\"]*)"$/ do |name|
  click_button(name)
end

When /^I click on "([^\"]*)"$/ do |link|
  click_link link, match: :first
end

When /^I check "([^\"]*)"$/ do |name|
  check name
end

When /^I uncheck "([^\"]*)"$/ do |name|
  uncheck name
end

Then /^the response should be (NG|OK)$/ do |condition|

  case condition
  when 'OK'
    (200...400).should include(page.status_code)

  when 'NG' then (200...400).should_not include(page.status_code)
  end

end

Then /^the response code should be (\d+)$/ do |code|
 page.status_code.should == code.to_i
end

Then /^the response contains "([^\"]*)"$/ do |blurb|
  page.should have_content(blurb)
end

Then /^the response does not contain "([^\"]*)"$/ do |blurb|
  page.should_not have_content (blurb)
end

Given /^I fill in "([^\"]*)" with "([^\"]*)"$/ do |field, value|
  fill_in field, :with => value, match: :first
end

Given /^I fill in "([^"]*)" with:$/ do |field, table|
  fill_in field, :with => table.raw.flatten.join(' ')
end

Then /^I cannot press "([^\"]*)"$/ do |name|
  lambda { click_button name }.should raise_error(Capybara::ElementNotFound, %Q(Unable to find button "#{name}"))
end

Then /^I should (be|not be) redirected to "([^"]*)"$/ do |cond, url|
  URI.parse(page.current_path).path.should == url if cond == 'be'
  step "I should #{cond} redirected"
end

Then /^I should (be|not be) redirected$/ do |cond|
  if cond == 'be'
    (200..399).should include(page.status_code) #redirects followed automatically in capybara. not sure what to do here
    #follow_redirect!
  else
    (300..399).should_not include(page.status_code)
  end

end

Then /^I should see "([^"]*)"$/ do |thing|
  page.should have_content(thing)
end

Then /^I should not see "([^"]*)"$/ do |thing|
  page.should_not have_content(thing)
end
