Given /^I goto its wip page$/ do
  step %Q(I goto "/workspace/#{last_package_id}")
end

Then /^the package should be (don't know|running|stop|idle)$/ do |status|

  unless status == "don't know"
    last_response.should have_selector("h1:contains('#{status}')")
  end

end

Then /^in the progress section I should see a field for "([^\"]*)"$/ do |field|
  pending 'not sure what we want here'
  last_response.should have_selector("td:contains('#{field}')")
end

When /^I wait for it to finish$/ do
  doc = Nokogiri::HTML last_response.body

  while doc % 'h1:contains("running")'
    sleep 0.5
    reload!
    doc = Nokogiri::HTML last_response.body
  end

  sleep 0.5
end

Then /^it should be snafu because "([^"]*)"$/ do |message|
  last_response.should have_selector('h2', :content => 'snafu')
  last_response.should have_selector('#snafu td', :content => message)
end
