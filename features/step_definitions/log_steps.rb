When /^I enter a log message "([^"]*)"$/ do |message|
  fill_in 'message', :with => message
end

Then /^I should see a log message "([^"]*)"$/ do |message|
  last_response.should have_selector("td:contains('#{message}')")
end

Then /^there should be an admin log entry:$/ do |table|
  Given "I goto \"/log\""

  table.hashes.each do |r|
    Then "I should see a log message \"#{r['message']}\""
  end

end

Then /^I should see an operator "([^"]*)"$/ do |op|
  last_response.should have_selector("td:contains('#{op}')")
end

