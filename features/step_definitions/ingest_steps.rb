Then /^the package is present in the aip store$/ do
  id = sips.last[:wip]
  package = Package.get(id)

  package.aip.should_not be_nil
end

#TODO: need to actually try to access the package
Then /^the package is present in storage$/ do
  id = sips.last[:wip]
  package = Package.get(id)

  package.aip.copy.url.should_not be_nil
end

Then /^there is an event for (.*)$/ do |event_type|
  id = sips.last[:wip]
  package = Package.get(id)

  package.events.all(:name => event_type).length.should == 1
end
