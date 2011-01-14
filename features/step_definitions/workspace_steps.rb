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
  when 'snafu'

    begin
      raise "oops this is not a real error!"
    rescue => e
      wip.make_snafu e
    end

    wip.should be_snafu

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

Then /^there should be (\d+) (running|idle|snafu|stopped|) ?wips?$/ do |count, state|

  if state == 'stopped'
    state = 'stop'
  end

  last_response.should be_ok
  doc = Nokogiri::HTML last_response.body

  unless state.empty?
    (doc / "td:contains('#{state}')").size.should == count.to_i
  else
    (doc / "tr td:first-child").size.should == count.to_i
  end

end

Then /^there should be the following wips:$/ do |table|

  table.hashes.each do |h|
    count = h['count']
    state = h['state']
    Then "there should be #{count} #{state} wips"
  end

end

When /^I select "([^\"]*)"$/ do |bin|
  select bin, :from => 'stash-bin'
end
