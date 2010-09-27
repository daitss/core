Given /^I submit "([^"]*)"$/ do |package|
  Given %q(I goto "/packages")
  When %Q(I select "#{package}" to upload)
  When %q(I press "Submit")
  last_response.should be_ok
  packages << current_url
end

Given /^I submit a package$/ do
  Given %q(I submit "haskell-nums-pdf")
end

Given /^I submit (\d+) packages$/ do |count|
  count.to_i.times { Given "I submit a package" }
end

When "I select a sip to upload" do
  When "I select \"haskell-nums-pdf\" to upload"
end

When /^I select "([^\"]*)" to upload$/ do |name|
  name = name + ".zip"
  zip_file = fixture(name)
  attach_file 'sip', zip_file
end

Then /^I should be at a package page$/ do
  current_url.should =~ %r{^/package/\w+}
end
