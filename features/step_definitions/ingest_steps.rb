Then /^the package is present in the aip store$/ do
  package = Package.get(last_package_id)
  package.aip.should_not be_nil
end

#TODO: need to actually try to access the package
Then /^the package is present in storage$/ do
  package = Package.get(last_package_id)
  package.aip.copy.url.should_not be_nil
end

Then /^there is an event for (.*)$/ do |event_type|
  package = Package.get(last_package_id)
  package.events.all(:name => event_type).length.should == 1
end

And /^there should be an "(normalize|migrate)" premis-event on "(.*)" file$/ do |event_type, origin|
  df = Datafile.first(:origin => origin)
  @premis_event = PremisEvent.first(:relatedObjectId => df.id, :e_type => event_type)
  @premis_event.should_not be_nil
end

And /^there should be an "(normalize|migrate|describe)" premis-event for "(.*)"$/ do |event_type, filepath|
#  package = Package.get(last_package_id)
#  package.intentity.id.should_not be_nil
  df = Datafile.first(:original_path => filepath)
  @premis_event = PremisEvent.first(:relatedObjectId => df.id, :e_type => event_type)
  @premis_event.should_not be_nil
end

And /^the outcome should be "([^\"]*)"$/ do |value|
  @premis_event.should_not be_nil
  @premis_event.outcome.should eq(value)
end

And /^the outcome_details should be "([^\"]*)"$/ do |value|
  @premis_event.should_not be_nil
  @premis_event.outcome_details.should eq(value)
end

And /^the event_details should be "([^\"]*)"$/ do |value|
  @premis_event.should_not be_nil
  @premis_event.event_detail.should eq(value)
end

Then /^there should have anomalies for "(.*)"$/ do |filepath|
   df = Datafile.first(:original_path => filepath) 
   anoamlies = DatafileSevereElement.all(:datafile_id => df.id)
   anoamlies.length.should >= 1
end