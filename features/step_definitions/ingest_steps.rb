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

Given /^a aip that will fail validation$/ do
  pending
end

Then /^the package should be rejected$/ do
  pending
end

Given /^a non ingested AIP$/ do
  pending
end

Given /^a set of events       \# that take place during ingest$/ do
  pending
end

Then /^the previous events should not be duplicated$/ do
  pending
end

Given /^an AIP$/ do
  pending
end

Given /^a error of any error when performing validation$/ do
  pending
end

Then /^the package should be snafu$/ do
  pending
end

Given /^a error of 500 error when performing per\-file$/ do
  pending
end

Given /^a error of 400 error when performing per\-file$/ do
  pending
end

Then /^the package should be ingested$/ do
  pending
end

Given /^a error of any error when performing serialization$/ do
  pending
end

Given /^a error of any error when performing store$/ do
  pending
end
