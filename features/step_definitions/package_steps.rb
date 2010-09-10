Given /^an archived package$/ do
  wip = submit 'haskell-nums-pdf.zip'
  wip.start
  sleep 0.5 while wip.running?
  wip.should_not be_snafu
end

When /^I goto its package page$/ do
  id = sips.last[:wip]
  visit "/package/#{id}"
end

Then /^in the submission summary I should see the (name|account|project)$/ do |field|
  last_response.should have_selector("th:contains('#{field}')")
end

Then /^in the jobs summary I should see an ingest wip$/ do
  id = sips.last[:wip]
  last_response.should have_selector("a[href='/workspace/#{id}']:contains('ingest')")
end

Then /^in the events I should see a submission event$/ do
  last_response.should have_selector("td:contains('submit')")
end

Then /^in the aip section I should see (copy url|copy size|copy sha1|number of datafiles)$/ do |field|
  last_response.should have_selector("th:contains('#{field}') + td")
end

Then /^in the aip section I should see a link to the descriptor$/ do
  id = sips.last[:wip]
  last_response.should have_selector("h3 a[href='/package/#{id}/descriptor']:contains('xml descriptor')")
end

Then /^in the jobs summary I should see a stashed ingest wip in "([^\"]*)"$/ do |bin_name|
  id = sips.last[:wip]
  bin = StashBin.first :name => bin_name
  last_response.should have_selector("a[href='/stashspace/#{bin.url_name}/#{id}']:contains('ingest')")
end

Then /^in the jobs summary I should see that no jobs are pending$/ do
  Then %Q(the response contains "no jobs processing")
  Then %Q(the response contains "no jobs stashed")
end
