When /^I enter the sip name into the box$/ do
  query = packages.map { |p| Package.get(p.split('/').last).sip.name }.join ' '
  fill_in "search", :with => query
end

When /^I enter the package ids? into the box$/ do
  query = packages.map { |p| Package.get(p.split('/').last).id }.join ' '
  fill_in "search", :with => query
end

When /^I enter one package id and one sip id into the box$/ do
  raise "need at least two sips" if packages.size < 2

  qa = []

  packages.each_with_index do |u, ix|
    p = Package.get u.split('/').last

    term = if ix % 2
             p.id
           else
             p.sip.name
           end

    qa << term
  end

  query = qa.join ' '

  fill_in "search", :with => query
end

Then /^I should see the packages? in the results$/ do
  packages.each do |s|
    last_response.should have_selector("td a[href='/package/#{last_package_id}']", :content => last_package_id)
  end

end

Then /^I should see the snafu error "([^"]*)" in the results$/ do |error|
  last_response.should have_selector("td", :content => error)
end


Then /^I should see that package in the results$/ do
  id = last_package ? last_package_id : Package.first.id
  last_response.should have_selector("td a[href='/package/#{id}']", :content => id)
end

Then /^I should not see the package in the results$/ do
  id = last_package ? last_package_id : Package.first.id
  last_response.should_not have_selector("td a[href='/package/#{id}']", :content => id)
end

Then /^I should see a "([^"]*)" heading$/ do |heading|
  doc = Nokogiri::HTML last_response.body
  rules = (1..3).map { |n| "h#{n}:contains('#{heading}')"}
  matches = doc.css *rules
  matches.should_not be_empty
end

Then /^I should see the following columns:$/ do |table|

  table.headers.each do |h|
    last_response.should have_selector("th:contains('#{h}')")
  end

end

Then /^the package column should link to a package$/ do
  last_response.should have_selector("td a[href*='/package/']")
end

Then /^I should have (\d+) package in the results$/ do |count|
  doc = Nokogiri::HTML last_response.body
  trs = doc / '#results tr'
  (trs.reject { |tr| tr % 'th'}).size.should == count.to_i
end

When /^I select batch "([^\"]*)"$/ do |batch|
  select batch, :from => 'batch-scope'
end

When /^I select account "([^\"]*)"$/ do |account|
  select account, :from => 'account-scope'
end

When /^I select project "([^\"]*)"$/ do |project|
  select project, :from => 'project-scope'
end

When /^I select activity "([^"]*)"$/ do |activity|
  select activity, :from => 'activity-scope'
end

When /^I select status "([^"]*)"$/ do |status|
  select status, :from => 'status-scope'
end

Then /^the latest activity should be "([^"]*)"$/ do |activity|
  last_response.should have_selector("td:contains('#{activity}')")
end

Then /^the timestamp should be "([^"]*)"$/ do |timestamp|
  last_response.should have_selector("td:contains('#{timestamp}')")
end

When /^I search for the package$/ do
  fill_in "search", :with => Package.first.id
end



