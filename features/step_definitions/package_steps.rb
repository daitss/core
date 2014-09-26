When /^I goto its package page$/ do
  visit last_package
end

When /^I goto its ingest report$/ do
  visit last_package + "/ingest_report"
end

When /^I goto its disseminate report$/ do
  visit last_package + "/disseminate_report"
end

When /^I goto its refresh report$/ do
  visit last_package + "/refresh_report"
end

When /^I goto its withdraw report$/ do
  visit last_package + "/withdraw_report"
end

When /^I goto its reject report$/ do
  visit last_package + "/reject_report"
end

Then /^in the submission summary I should see the (name|account|project)$/ do |field|
  page.should have_selector("th:contains('#{field}')")
end

Then /^in the jobs summary I should see an ingest wip$/ do
  page.should have_selector("a[href='/workspace/#{last_package_id}']", :text => 'ingesting')
end

Then /^in the events I should see a "(.*?)" event with "(.*?)" in the notes$/ do |event, notes|
  pending notes if notes =~ %r{\?$}
  page.should have_selector(%Q{td:contains("#{event}")})
  page.should have_selector(%Q{td:contains("#{notes}")})
end

Then /^in the events I should not see a "([^\"]*)" event with "([^"]*)" in the notes$/ do |event, notes|
  pending notes if notes =~ %r{\?$}
  page.should have_selector("td:contains('#{event}')")
  page.should_not have_selector("td:contains('#{notes}')")
end

Then /^in the events I should not see a "([^\"]*)" event$/ do |event|
  page.should_not have_selector("td:contains('#{event}')")
end

Then /^in the aip section I should see (copy url|aip size|copy sha1|number of datafiles)$/ do |field|
  page.should have_selector("th:contains('#{field}') + td")
end

Then /^in the aip section I should see a link to the descriptor$/ do
  page.should have_selector("a[href='/package/#{last_package_id}/descriptor']")
end

Then /^in the jobs summary I should see a stashed ingest wip in "([^\"]*)"$/ do |bin_name|
  bin = Daitss.archive.stashspace.find { |b| b.name == bin_name }
  bin.should_not be_nil
  page.should have_selector("a[href='/stashspace/#{bin.id}/#{last_package_id}']", :text => 'stashed')
end

Then /^in the jobs summary I should see that no jobs are pending$/ do
  step %Q(the response contains "archived")
end

Then /^there (should not|should) be an "([^"]*)" event$/ do |presence, event|

  if presence == 'should'
    page.should have_selector("td", :text => event)
  else
    page.should_not have_selector("td", :text => event)
  end

end

Then /^the "([^"]*)" event should have note "([^"]*)"$/ do |event, note|
  Event.first(:name => event).notes.should =~ /#{note}/
end


When /^I choose request type "([^"]*)"$/ do |type|

  page.within "#request" do
    select type, :from => 'type'
  end

end

When /^I fill in request note with "([^"]*)"$/ do |note|

  page.within "#request" do
    fill_in 'note', :with => note
  end

end

When /^I fill in cancel note with "([^"]*)"$/ do |note|

  page.within "#request" do
    fill_in 'cancel_note', :with => note
  end

end



Then /^I should see a ([^"]*) request$/ do |type|
  step %Q(I goto its package page)
  page.should have_selector("#request table tr td", :text => type)
end

Then /^I should see a ([^"]*) request with note "([^"]*)" and authorized "(yes|no)"$/ do |type, note, auth|
  step %Q(I goto its package page)
  page.should have_selector("#request table tr td", :text => type)
  page.should have_selector("#request table tr td", :text => note)
  page.should have_selector("#request table tr td", :text => auth)
end

Then /^I should see a ([^"]*) request with status "([^"]*)"$/ do |type, status|
  step %Q(I goto its package page)
  page.should have_selector("#request table tr td", :text => type)
  page.should have_selector("#request table tr td", :text => status)
end

Then /^there should be a request heading$/ do
  page.should have_selector("#request h2", :text => 'requests')
end

Then /^there should be a request form$/ do
  page.should have_selector("#request")
end

Then /^there should (be|not be) a request table$/ do |cond|

  if cond == 'be'
    page.should have_selector("#request table")
  else
    page.should_not have_selector("#request table")
  end

end

Given /^a ([^"]*) request$/ do |type|
  visit last_package
  step %Q(I choose request type "#{type}")
  step %Q(I fill in "note" with "do it, please")
  step %Q(I press "Request")
 step %Q(I should see a #{type} request)
end

When /^I press "([^"]*)" for the request$/ do |button|

  within "#request table tr td form" do
    click_button button
  end

end

Then /^I should not see the request$/ do
  page.should_not have_selector("#request table tr")
end

# ensure that response can be parsed as xml and contains the IEID
# TODO: thorough ingest report testing, checking contents against database
Then /^the response should contain a valid (?:ingest|disseminate|refresh|withdraw) report$/ do
  page.body.should_not be_nil

  doc = Nokogiri::XML page.body
  ieid = File.basename last_package
  page.body.should match /#{ieid}/
end

Then /^the response should contain a valid reject report$/ do
  page.body.should_not be_nil
  upath = URI.parse(current_url).path.split('/')
  ieid = upath[2]
  page.body.should match /#{ieid}/
end

Then /^the body should be mets xml$/ do
  doc = Nokogiri::XML page.body
  doc.root.name.should == 'mets'
  doc.root.namespace.href.should == "http://www.loc.gov/METS/"
end

Then /^there should be link to a dip$/ do
  page.should have_selector("a[href='/package/#{last_package_id}/dip/#{last_package_id}-0.tar']")
end

Then /^clicking the dip link downloads the tarball$/ do
  click_link "#{last_package_id}-0.tar"
  (200..399).should include(page.status_code)
end

Then /^there should be a report delivery record$/ do
  ReportDelivery.first(:package_id => File.basename(last_package)).should_not be_nil
end

Then /^there should be a reject report delivery record$/ do
  ReportDelivery.first(:package => Package.first, :type => :reject).should_not be_nil
end

Given /^(\d+) package under account\/project "([^"]*)"$/ do |number, account_project|
  account, project = account_project.split("-")
  a = Account.first_or_create(:id => account)
  p = a.projects.first_or_create(:id => project)

  p.saved? or raise "can't save project"

  number.to_i.times do |i|
    s = Sip.new :name => i
    pa = Package.new
    pa.sip = s
    pa.project = p
    pa.save

    pa.log "ingest finished"
  end
end

Given /^(\d+) package snafued under account\/project "([^"]*)"$/ do |number, account_project|
  account, project = account_project.split("-")
  a = Account.first_or_create(:id => account)
  p = a.projects.first_or_create(:id => project)

  p.saved? or raise "can't save project"

  number.to_i.times do |i|
    s = Sip.new :name => i
    pa = Package.new
    pa.sip = s
    pa.project = p
    pa.save

    pa.log "submit"
    pa.log "ingest started"
    pa.log "ingest snafu"
  end
end



Given /^an account\/project "([^"]*)"$/ do |account_project|
  account, project = account_project.split("-")
  a = Account.first_or_create(:id => account)
  p = a.projects.first_or_create(:id => project)

  p.saved? or raise "can't save project"
end

Given /^(\d+) rejected package$/ do |count|
  count.to_i.times do |i|
    s = Sip.new :name => i
    pa = Package.new
    pa.sip = s
    pa.project = Project.first
    pa.save

    pa.log "reject"
  end
end

Given /^(\d+) archived package$/ do |count|
  count.to_i.times do |i|
    s = Sip.new :name => i, :size_in_bytes => (1024 * 871), :number_of_datafiles => 3
    pa = Package.new
    pa.sip = s
    pa.project = Project.first
    pa.save

    pa.log "ingest finished"
  end
end

Given /^(\d+) legacy package$/ do |count|
  count.to_i.times do |i|
    s = Sip.new :name => i, :size_in_bytes => (1024 * 871), :number_of_datafiles => 3
    pa = Package.new
    pa.sip = s
    pa.project = Project.first
    pa.save

    pa.log "daitss v.1 provenance"
    pa.log "legacy operations data", :timestamp => Time.parse("2011-01-01 11:11:11")
  end
end



Given /^(\d+) snafu package$/ do |count|
  count.to_i.times do |i|
    s = Sip.new :name => i
    pa = Package.new
    pa.sip = s
    pa.project = Project.first
    pa.save

    pa.log("submit")
    pa.log("ingest started")
    pa.log("ingest snafu")
  end
end

Given /^(\d+) disseminated package$/ do |count|
  count.to_i.times do |i|
    s = Sip.new :name => i
    pa = Package.new
    pa.sip = s
    pa.project = Project.first
    pa.save

    pa.log "disseminate finished"
  end
end

Given /^(\d+) submitted package$/ do |count|
  count.to_i.times do |i|
    s = Sip.new :name => i
    pa = Package.new
    pa.sip = s
    pa.project = Project.first
    pa.save

    pa.log "submit"
  end
end

Then /^I should see a comment with "([^"]*)" by operator$/ do |notes|
  page.should have_selector(%Q{td:contains("operator")})
  page.should have_selector(%Q{td:contains("#{notes}")})
  page.should have_selector(%Q{td:contains("#{Comment.first.timestamp.strftime("%a %b %d %Y %I:%M:%S %p")}")})
end

When /^the request is picked up by pulse and sent to workspace$/ do
  r = Request.first
  r.status = :released_to_workspace
  r.save
end

Given /^the package is missing its copy record$/ do
  p = Package.get(File.basename(last_package))
  p.aip.copy.destroy
end

Then /^there should be a datafile with:$/ do |table|

  table.hashes.each do |row|
    cell_conditions = row.values.map { |v| "td = '#{v}'"}.join ' and '
    page.should have_xpath("//tr[#{cell_conditions}]")
  end

end

