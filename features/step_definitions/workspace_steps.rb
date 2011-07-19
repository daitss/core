Given /^an? ([^"]*) package$/ do |state|
  Given %Q(a #{state} wip)
end

Given /^an? ([^"]*) wip$/ do |state|
  Given "I submit a package"
  last_response.should be_ok

  # TODO implement all of this 'over-the-hood'
  #When %Q(I click on "ingesting")
  #When %Q(I choose "start")
  #When %Q(I press "Update")

  wip = Daitss.archive.workspace[last_package_id]
  raise "no wip: #{last_package_id}" unless wip

  case state
  when 'idle', ""
  when 'snafu', 'error'

    begin
      raise "oops this is not a real error!"
    rescue => e
      wip.make_snafu e
      Package.get(wip.id).log "ingest snafu", :notes => "oops this is not a real error!"
    end

    wip.should be_snafu

  when 'different snafu'

    begin
      raise "oops this is not a real error!"
    rescue => e
      wip.make_snafu e
      Package.get(wip.id).log "ingest snafu", :notes => "this is a different fake error"
    end

    wip.should be_snafu


  when 'previously ingested disseminate snafu'

    begin
      p = Package.get(wip.id)
      p.log "ingest started"
      p.log "ingest finished"
      raise "oops this is not a real error!"
    rescue => e
      wip.make_snafu e
      sleep 1
      p.log "disseminate snafu"
    end

    wip.should be_snafu

  when 'stashed snafu'

    begin
      raise "oops this is not a real error!"
    rescue => e
      wip.make_snafu e
      p = Package.get(wip.id)
      p.log "ingest snafu", :notes => "oops this is not a real error!"
      p.log "stash"
    end

    wip.should be_snafu

  when 'unsnafued snafu'

    begin
      raise "oops this is not a real error!"
    rescue => e
      wip.make_snafu e
      p = Package.get(wip.id)
      p.log "ingest snafu", :notes => "oops this is not a real error!"
      p.log "ingest unsnafu"
    end

  when 'stop'
    wip.spawn
    wip.stop
    wip.should be_stopped

  when 'running'
    wip.spawn
    wip.should be_running

  when 'dead'
    wip.spawn
    Process.kill 'KILL', wip.process[:id]
    sleep 0.5
    wip.should be_dead

  when 'archived'
    wip.spawn
    sleep 0.5 until wip.done?
    wip.should_not be_dead
    wip.should_not be_snafu

  else raise "unknown state: #{state}"
  end

end

Given /^(\d+) (running|idle|snafu|stopped|) ?wips?$/ do |count, state|

  if state == 'stopped'
    state = 'stop'
  end

  count.to_i.times { Given "a #{state} wip" }
end

Given /^a workspace with the following wips:$/ do |table|

  table.hashes.each do |h|
    count = h['count']
    state = h['state']
    Given %Q(#{count} #{state} wips)
  end

end

When /^all running wips have finished$/ do
  while true
    visit "/workspace"
    last_response.should be_ok
    doc = Nokogiri::HTML last_response.body

    if (doc / "td:contains('running')").size == 0
      break
    end
    sleep 0.5
  end
end

Then /^there should be (\d+) (running|snafu|stopped|) ?wips?$/ do |count, state|

  if state == 'stopped'
    state = 'stop'
  end

  last_response.should be_ok
  doc = Nokogiri::HTML last_response.body

  unless state.empty?
    (doc / "#results td:contains('#{state}')").size.should == count.to_i
  else
    (doc / "#results tr td:first-child").size.should == count.to_i
  end

end

Then /^there should be the following wips:$/ do |table|

  table.hashes.each do |h|
    count = h['count']
    state = h['state']
    Then "there should be #{count} #{state} wips"
  end

end

Then /^there should be (\d+) idle wips listed in the table$/ do |count|
  last_response.should be_ok
  doc = Nokogiri::HTML last_response.body

  (doc / "#idles td:contains('#{count}')").size.should == 1
end

Then /^the idle table should be zeroed out$/ do
  last_response.should be_ok
  doc = Nokogiri::HTML last_response.body

  (doc / "#idles td:contains('0')").size.should == 4
end


When /^I select "([^\"]*)"$/ do |bin|
  select bin, :from => 'stash-bin'
end

Then /^I should have (\d+) wips in the results$/ do |count|
  doc = Nokogiri::HTML last_response.body
  trs = doc / '#results tr'
  (trs.reject { |tr| tr % 'th'}).size.should == count.to_i
end

Given /^(\d+) (stopped|idle|snafu) wips in batch "([^"]*)"$/ do |count, state, batch|
  b = Batch.new :id => batch
  count.to_i.times do |i|
    Given "a stop wip" if state == "stopped"
    Given "a snafu wip" if state == "snafu"

    p = Package.get(last_package_id)
    b.packages << p
    b.save
  end
end

Given /^(\d+) stopped wips under account\/project "([^"]*)"$/ do |count, account_project|
  account, project = account_project.split("-")
  a = Account.first_or_create(:id => account)
  p = a.projects.first_or_create(:id => project)

  p.saved? or raise "can't save project"

  count.to_i.times do |i|
    Given "a stop wip"

    pa = Package.get(last_package_id)
    pa.project = p
    pa.save
  end
end

Then /^the journal file for the wip should be empty$/ do
  wip = Daitss.archive.workspace[last_package_id]
  f = File.open(File.join(wip.path, "journal"), "r")
  Marshal.load(f).should == {}
end



