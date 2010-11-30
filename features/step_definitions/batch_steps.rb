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
  debugger

  # b = Batch.new :name => name

  table.raw.each do |r|
    wip = submit 'haskell-nums-pdf'
    p = wip.package
    p.update :ieid => r[package]
    #b.packages << p
  end

  # b.save



end

When /^I fill in the form with packages:$/ do |table|
  # table is a Cucumber::Ast::Table
  pending # express the regexp above with the code you wish you had
end

Then /^I should have a batch containing:$/ do |table|
  # table is a Cucumber::Ast::Table
  pending # express the regexp above with the code you wish you had
end

Then /^I should not have batch "([^"]*)"$/ do |arg1|
  pending # express the regexp above with the code you wish you had
end

Given /^I fill in the form with the packages:$/ do |table|
  # table is a Cucumber::Ast::Table
  pending # express the regexp above with the code you wish you had
end

Then /^I should have a batch containing$/ do |table|
  # table is a Cucumber::Ast::Table
  pending # express the regexp above with the code you wish you had
end
