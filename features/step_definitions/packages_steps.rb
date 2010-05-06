When /^I enter the sip name into the box$/ do
  query = sips.map { |s| s[:sip] }.join ' '
  fill_in "search", :with => query
end

When /^I enter the package ids? into the box$/ do
  query = sips.map { |s| s[:wip] }.join ' '
  fill_in "search", :with => query
end

When /^I enter one package id and one sip id into the box$/ do
  raise "need at least two sips" if sips.size < 2
  query = "#{sips.first[:wip]} #{sips.last[:sip]}"
  fill_in "search", :with => query
end

Then /^I should see the packages? in the results$/ do

  sips.each do |s|
    id = s[:wip]
    last_response.should have_selector("ol.results li a[href='/package/#{id}']:contains('#{id}')")
  end

end
