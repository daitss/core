Given /^the following users:$/ do |users|
  User.create!(users.hashes)
end

When /^I delete the (\d+)(?:st|nd|rd|th) user$/ do |pos|
  visit users_path
  within("table tr:nth-child(#{pos.to_i+1})") do
    click_link "Destroy"
  end
end

Then /^I should see the following users:$/ do |expected_users_table|
  expected_users_table.diff!(tableish('table tr', 'td,th'))
end

Given /^(\d+) arbitrary users$/ do |count|
  count.to_i.times { User.make }
  @arbitrary_users = Array.new count.to_i, User.make
end

Then /^I should see all the arbitrary users$/ do

  @arbitrary_users.each do |u|
    Then %Q{I should see "#{u.id}"}
    Then %Q{I should see "#{u.first_name}"}
    Then %Q{I should see "#{u.last_name}"}
    Then %Q{I should see "#{u.account.id}"}
  end

end

Given /^a user "([^"]*)"$/ do |id|
  User.make :id => id
end
