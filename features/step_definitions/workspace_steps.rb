
Given /^an empty workspace$/ do
  ws = Workspace.new Daitss::CONFIG['workspace']

  ws.each do |wip|
    wip.stop if wip.running?
    FileUtils.rm_r wip.path
  end

end

Given /^I goto "([^\"]*)"$/ do |path|
  visit path
end

When /^I choose "([^\"]*)"$/ do |name|
  choose name
end

When /^I press "([^\"]*)"$/ do |name|
  click_button name
end

Then /^there should be (\d+) running sips?$/ do |count|
  doc = Nokogiri::HTML last_response.body
  (doc / "table#wips tr td.state:contains('running')").size.should == count.to_i
end

When /^I click on "([^\"]*)"$/ do |link|
  click_link link
end

Then /^there should be (\d+) wips?$/ do |count|
  doc = Nokogiri::HTML last_response.body
  (doc / "table#wips tr").size.should == count.to_i
end

Given /^I submit (a|\d+) sips?$/ do |count|

  count = case count
          when 'a' then 1
          when /\d+/ then count.to_i
          else raise 'invalid count'
          end

  count.times { submit 'ateam' }

end

Then /^the response should be OK$/ do
  last_response.should be_ok
end

Given /^a workspace with (\d+) (running|idle|snafu) wips?$/ do |count, state|

  count.to_i.times do

    wip = submit 'mimi'

    case state
    when 'idle'
    when 'snafu'

      begin
        raise "oops this is not a real error!"
      rescue => e
        wip.snafu = e
      end

    when 'stopped' then wip.stop
    when 'running' then wip.start_task
    end

  end

end

Then /^there should be (\d+) (running|idle|snafu) wips?$/ do |count, state|
  doc = Nokogiri::HTML last_response.body
  (doc / "table#wips tr td:contains('#{state}')").size.should == count.to_i
end

