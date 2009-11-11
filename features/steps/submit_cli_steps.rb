Given /^a bogus DAITSS_WORKSPACE$/ do
  ENV['DAITSS_WORKSPACE'] = '/does/not/exist'
end

When /^I submit$/ do
  @output = `ruby -Ilib bin/submit #{@sip_path}`
end

Given /^no sip as an argument$/ do
  @sip_path = ''
end

Given /^a good sip$/ do
  @sip_path = test_sip_by_name 'ateam'
end
