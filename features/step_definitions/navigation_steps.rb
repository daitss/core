Given /^I goto "([^\"]*)"$/ do |path|
  visit path
end

When /^I choose "([^\"]*)"$/ do |name|
  choose name
end

When /^I press "([^\"]*)"$/ do |name|
  click_button name
end

When /^I click on "([^\"]*)"$/ do |link|
  click_link link
end

Then /^the response should be (NG|OK)$/ do |condition|

  case condition
  when 'OK'
    (200...400).should include(last_response.status)

    if (300..399).include? last_response.status
      follow_redirect!
    end

  when 'NG' then last_response.should_not be_ok
  end

end

Then /^the response code should be (\d+)$/ do |code|
  last_response.status.should == code.to_i
end

Then /^the response contains "([^\"]*)"$/ do |blurb|
  last_response.should contain(blurb)
end

Given /^I fill in "([^\"]*)" with "([^\"]*)"$/ do |field, value|
  fill_in field, :with => value
end

Then /^I cannot press "([^\"]*)"$/ do |name|
  lambda { click_button name }.should raise_error(Webrat::NotFoundError, %Q(Could not find button "#{name}"))
end

Then /^I should (be|not be) redirected to "([^"]*)"$/ do |cond, url|
  URI.parse(last_response['Location']).path.should == url if cond == 'be'
  Then "I should #{cond} redirected"
end

Then /^I should (be|not be) redirected$/ do |cond|

  if cond == 'be'
    (300..399).should include(last_response.status)
    follow_redirect!
  else
    (300..399).should_not include(last_response.status)
  end

end
