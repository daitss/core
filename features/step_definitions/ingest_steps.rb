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
  @url = "file://" + test_package('empty')
end

Given /^a partially ingested AIP$/ do
  @url = "file://" + test_package('incomplete')
  # TODO build list of pre existing events
end

Then /^it should be ingested$/ do
  pending
end

Then /^there should be no duplicate events$/ do
  # TODO check pre existing events for dupl
  pending
end

Given /^a good AIP$/ do
  @url = "file://" + test_package('ateam')
end

Given /^a error of (any|\d{3}) error when performing (.+)$/ do |status, service|
  # TODO mock up a server that will accept anything
  # but return the http error code
  pending
end

Then /^the package should be (ingested|rejected|snafu)$/ do |status|
  # TODO scan the events for the proper one
  pending
end
