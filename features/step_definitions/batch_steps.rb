Given /^the following packages:$/ do |table|

  table.raw.each do |r|
    id = r.first
    sip = Sip.new :name => 'foo.sip'
    p = Package.create :id => id, :sip => sip, :project => Project.first
    p.log "submit"
  end

end

Given /^the following (rejected|withdrawn) packages:$/ do |status, table|
  table.raw.each do |r|
    id = r.first
    sip = Sip.new :name => 'foo.sip'
    p = Package.create :id => id, :sip => sip, :project => Project.first

    case status
    when "rejected"
      p.log "reject"
    when "withdrawn"
      p.log "submit"
      p.log "ingest started"
      p.log "ingest finished"
      p.log "withdraw started"
      p.log "withdraw finished"
    end
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

Then /^I (should|should not) have a (disseminate|withdraw|peek) request for the following packages:$/ do |has, type, table|
  table.raw.each do |r|
    p = Package.get(r)
    raise "package not found" unless p

    if has == "should"
      raise "no #{type} request found for #{r}" unless p.requests.first(:type => type, :status => :enqueued)
    elsif has == "should not"
      raise "#{type} request found for #{r}" if p.requests.first(:type => type, :status => :enqueued)
    end
  end
end

When /^I select type "([^\"]*)"$/ do |type|
  select type, :from => 'type'
end

Then /^the batch should contain the last package ingested$/ do
  Then "the response contains \"#{last_package_id}\""
end

Given /^a batch "([^"]*)"$/ do |name|
  b = Batch.new :id => name
  b.save
end

Then /^I should see (\d+) packages in batch "([^"]*)"$/ do |num, name|
  b = Batch.get(name)
  b.packages.length.should == num.to_i
end

