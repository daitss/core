When /^I enter a log message "([^"]*)"$/ do |message|
  fill_in 'message', :with => message
end

Then /^I should see a log message "([^"]*)"$/ do |message|
  last_response.should have_selector("td:contains('#{message}')")
end
