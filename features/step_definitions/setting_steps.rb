Given /^the following settings:$/ do |settings|
  Setting.create!(settings.hashes)
end

When /^I delete the (\d+)(?:st|nd|rd|th) setting$/ do |pos|
  visit settings_path
  within("table tr:nth-child(#{pos.to_i+1})") do
    click_link "Destroy"
  end
end

Then /^I should see the following settings:$/ do |expected_settings_table|
  expected_settings_table.diff!(tableish('table tr', 'td,th'))
end
