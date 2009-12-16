Given /^a bogus WORKSPACE$/ do
  ENV['WORKSPACE'] = '/does/not/exist'
end

When /^I submit$/ do
  @last_output = `ruby -Ilib bin/submit #{@sip_path}`
end

Given /^no sip as an argument$/ do
  @sip_path = ''
end

Given /^a sip$/ do
  @sip_path = test_sip_by_name 'ateam'
end

Then /^it should have a submit agent$/ do
  @last_output =~ %r{(.+/)(.+) successfully submitted}
  prefix = $1
  id = $2
  w = Wip.new File.join(ENV['WORKSPACE'], id), prefix
  w['submit-agent'].should_not be_nil
  w['submit-agent'].should_not be_empty
end

Then /^it should have a submit event$/ do
  @last_output =~ %r{(.+/)(.+) successfully submitted}
  prefix = $1
  id = $2
  w = Wip.new File.join(ENV['WORKSPACE'], id), prefix
  w['submit-event'].should_not be_nil
  w['submit-event'].should_not be_empty
end
