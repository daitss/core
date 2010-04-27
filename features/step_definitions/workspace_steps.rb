require 'net/http'

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

  count.times do |i|
    sip_path = sip 'ateam'
    url = URI.parse "#{Daitss::CONFIG['submission-url']}"
    req = Net::HTTP::Post.new url.path
    tar = %x{tar -c -C #{File.dirname sip_path} -f - #{File.basename sip_path} }
    raise "tar did not work" if $?.exitstatus != 0
    req.body = tar
    req.content_type = 'application/tar'
    req.basic_auth 'operator', 'operator'
    req['X-Package-Name'] = File.basename sip_path
    req['Content-MD5'] = Digest::MD5.hexdigest(req.body)
    req['X-Archive-Type'] = 'tar'

    res = Net::HTTP.start(url.host, url.port) do |http|
      http.read_timeout = Daitss::CONFIG['http-timeout']
      http.request req
    end

    res.error! unless Net::HTTPSuccess === res
  end

end

Then /^the response should be OK$/ do
  last_response.should be_ok
end

