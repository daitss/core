Given /^I submit (a|another) package$/ do |article|
  sip = test_sip_by_name('ateam')
  bin "submit #{sip}"  
  @aips = Dir["#{ENV['DAITSS_WORKSPACE']}/*"]
end

Given /^it is tagged (\w+)$/ do |tag|
  aip = @aips.first 
  FileUtils.touch File.join(aip, tag)
end
