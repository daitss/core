Given /^the following packages:$/ do |table|

  table.raw.each do |r|
    id = r.first
    sip = Sip.new :name => 'foo.sip'
    Package.create :id => id, :sip => sip, :project => Project.first
  end

end

Then /^I should have a batch containig those IEIDs$/ do
  pending # express the regexp above with the code you wish you had
end

Given /^batch "([^"]*)" with the following packages:$/ do |name, table|
   b = Batch.new :id => name

  table.raw.each do |r|
    raise "Package #{r} not found" unless p = Package.get(r)
    b.packages << p
  end

  b.save
end

Then /^I should not have batch "([^"]*)"$/ do |arg1|
    Then "the response does not contain \"#{arg1}\""
end

Then /^I should have a batch containing$/ do |table|
  table.raw.each do |r|
    Then "the response contains \"#{r}\""
  end
end

Then /^I should have a batch not containing$/ do |table|
  table.raw.each do |r|
    Then "the response does not contain \"#{r}\""
  end
end
