Given /^an? (invalid|valid) AIP$/ do |validity|
  name = validity == "invalid" ? "invalid-descriptor" : "ateam"
  @handler.aips['name'] = sip_by_name name

  @aip = Aip.new @archive, name
end

When "it is ingested" do
  @aip.ingest
end

Then /^it should (be rejected|not be rejected)$/ do |status|

  if status == "not be rejected"
    @aip.should_not be_rejected
  else
    @aip.should be_rejected
  end

end

And /^a validation event should (exist|not exist)?$/ do |existence|
  validation_events = @aip.events.select { |e| e.action == "package validation" }
  
  if existence == "not exist"
    validation_events.should be_empty
  else
    validation_events.should_not be_empty
  end
  
end
