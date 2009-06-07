Given /^an (unresolvable|unknown) package url$/ do |type|
  @url = case type
         when 'unknown'
           'xxx://should/not/work'
         when 'unresolvable'
           'file://should/not/work'
         end
end

When /^I ingest it$/ do
  @output = `ruby -Ilib bin/ingest #{@url}`
end

Then /^I should get an (unresolvable|unknown) error$/ do |type|

  case type
  when 'unresolvable'
    @output.should match(/cannot locate package/)
  when 'unknown'
    @output.should match(/unsupported url/)
  end

end

Given /^an aip that will fail validation$/ do
  @url = "file:" + package_instance('empty')
end

Given /^a partially ingested AIP$/ do
  path = package_instance('incomplete')
  @url = "file:" + path
end

Then /^there should be no duplicate events$/ do
  descriptor = File.join URI.parse(@url).path, 'descriptor.xml'
  doc = XML::Parser.file(descriptor).parse

  types = []
  doc.find('//premis:event', NS_MAP).each do |e|
    et = e.find_first('premis:eventType', NS_MAP).content.strip
    types.should_not include(et)
    types << et
  end
  
end

Given /^a good AIP$/ do
  pending
  @url = "file://" + test_package('ateam')
end

Given /^a error of (any|\d{3}) error when performing (.+)$/ do |status, service|
  # TODO mock up a server that will accept anything
  # but return the http error code
  pending
end

Then /^the package should be (ingested|rejected|snafu)$/ do |status|
  @output.should match(/#{status}/m)
end
