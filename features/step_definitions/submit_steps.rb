Given /^I submit "([^"]*)"$/ do |package|
  step %q(I goto "/packages")
  step %Q(I select "#{package}" to upload)
  step %q(I press "Submit")
  step %q(I should be at a package page)
  #cleanup after each submit
  rm_fixture(package)
  last_response.should be_ok
  packages << last_request.env["PATH_INFO"]
  
end

Given /^(\d+) packages ingested on "([^"]*)"$/ do |count, date|
  count.to_i.times do |t|
    s = Sip.new :name => t
    p = Package.new :project => Project.first, :sip => s
    p.save or "can't save package"

    t = Time.strptime(date, "%m/%d/%Y")
    p.log("submit", :timestamp => t)
    p.log("ingest finished", :timestamp => t)
    
  end
end

Given /^(\d+) packages snafued on "([^"]*)"$/ do |count, date|
  count.to_i.times do |t|
    s = Sip.new :name => t
    p = Package.new :project => Project.first, :sip => s
    p.save or "can't save package"

    t = Time.strptime(date, "%m/%d/%Y")
    p.log("submit", :timestamp => t)
    p.log("ingest started", :timestamp => t)
    p.log("ingest snafu", :timestamp => t)
  end
end

Given /^(\d+) packages under batch "([^"]*)"$/ do |count, batch|
  b = Batch.new :id => batch
  count.to_i.times do |t|
    s = Sip.new :name => t
    p = Package.new :project => Project.first, :sip => s

    b.packages << p

    p.save or "can't save package"
    p.log "ingest finished"
  end

  b.save
end

Given /^(\d+) packages snafued under batch "([^"]*)"$/ do |count, batch|
  b = Batch.new :id => batch
  count.to_i.times do |t|
    s = Sip.new :name => t
    p = Package.new :project => Project.first, :sip => s

    b.packages << p

    p.save or "can't save package"
    p.log "submit"
    p.log "ingest started"
    p.log "ingest snafu"
  end

  b.save
end

Given /^I submit a package$/ do
  step %q(I submit "haskell-nums-pdf")
end

Given /^I submit a package with some legacy events$/ do
  step %q(I submit "haskell-nums-pdf")
  p = Package.get last_package_id
  p.log 'legacy operations data'
end

Given /^I submit a package with some fixity events$/ do
  step %q(I submit "haskell-nums-pdf")
  p = Package.get last_package_id
  p.log 'fixity success'
  p.log 'fixity failure'
end

Given /^I submit (\d+) packages$/ do |count|
  count.to_i.times { step "I submit a package" }
end

When "I select a sip to upload" do
  step "I select \"haskell-nums-pdf\" to upload"
end

When /^I select "([^\"]*)" to upload$/ do |name|
  pending if name == "multiple-agreements"
  pending if name == "lower-level-special-characters"
  case name
  when "non-package-text" then name = name + ".xyz"
  when "non-package-tar" then name = name + ".tar"
  else name = name + ".zip"
  end
  zip_file = fixture(name)
  attach_file 'sip', zip_file
end

Then /^I should be at a package page$/ do
  follow_redirect! if last_response.status == 302
  last_request.env['PATH_INFO'].should =~ %r{^/package/\w+}
end

Then /^the submitted datafiles field should show (\d+) files$/ do |count|
  p = Package.first
  p.sip.submitted_datafiles.should == count.to_i
end

Then /^the described datafiles field should show (\d+) files$/ do |count|
  p = Package.first
  p.sip.number_of_datafiles.should == count.to_i
end


