When /^I goto its package page$/ do
  visit last_package
end

Then /^in the submission summary I should see the (name|account|project)$/ do |field|
  last_response.should have_selector("th:contains('#{field}')")
end

Then /^in the jobs summary I should see an ingest wip$/ do
  last_response.should have_selector("a[href='/workspace/#{last_package_id}']", :content => 'ingesting')
end

Then /^in the events I should see a "([^\"]*)" event with "([^"]*)" in the notes$/ do |event, notes|
  pending notes if notes =~ %r{\?$}
  last_response.should have_selector("td:contains('#{event}')")
  last_response.should have_selector("td:contains('#{notes}')")
end

Then /^in the aip section I should see (copy url|copy size|copy sha1|number of datafiles)$/ do |field|
  last_response.should have_selector("th:contains('#{field}') + td")
end

Then /^in the aip section I should see a link to the descriptor$/ do
  last_response.should have_selector("h3 a[href='/package/#{last_package_id}/descriptor']", :content => 'xml descriptor')
end

Then /^in the jobs summary I should see a stashed ingest wip in "([^\"]*)"$/ do |bin_name|
  bin = StashBin.first :name => bin_name
  last_response.should have_selector("a[href='/stashspace/#{bin.url_name}/#{last_package_id}']", :content => 'stashed')
end

Then /^in the jobs summary I should see that no jobs are pending$/ do
  Then %Q(the response contains "archived")
end

Then /^there (should not|should) be an "([^"]*)" event$/ do |presence, event|

  if presence == 'should'
    last_response.should have_selector("td", :content => event)
  else
    last_response.should_not have_selector("td", :content => event)
  end

end
