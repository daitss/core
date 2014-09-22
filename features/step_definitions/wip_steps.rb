Given /^I goto its wip page$/ do
  step %Q(I goto "/workspace/#{last_package_id}")
end

Then /^the package should be (don't know|running|stop|idle)$/ do |status|

  unless status == "don't know"
    page.should have_selector("h1:contains('#{status}')")
  end

end

Then /^in the progress section I should see a field for "([^\"]*)"$/ do |field|
  pending 'not sure what we want here'
  page.should have_selector("td:contains('#{field}')")
end

When /^I wait for it to finish$/ do
  doc = Nokogiri::HTML page.body

  while doc % 'h1:contains("running")'
    sleep 0.5
    reload!
    doc = Nokogiri::HTML page.body
  end

  sleep 0.5
end

Then /^it should be snafu because "([^"]*)"$/ do |message|
  page.should have_selector('h2', :text => 'snafu')
  page.should have_selector('#snafu td', :text => message)
end
