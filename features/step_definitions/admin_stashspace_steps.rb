Given /^a stash bin named "([^\"]*)"$/ do |name|
  step %Q(I goto "/stashspace")
  step %Q(I fill in "name" with "default bin")
  step %Q(I press "Create")
  step 'I should be redirected to "/stashspace"'
  last_response.should be_ok
  @the_bin = Daitss.archive.stashspace.find { |b| b.name == name }
  @the_bin.should_not be_nil
end

Given /^a stash bin named "([^\"]*)" with (\d+) package$/ do |name, count|
  step %Q(a stash bin named "#{name}")
  step "#{count} idle wips"
  step %Q(I goto "/workspace")
  step %Q(I choose "stash")
  step %Q(I select "#{@the_bin.name}")
  step %Q(I press "Update")
end

Then /^there should (be|not be) a stash bin named "([^\"]*)"$/ do |presence, name|

  case presence
  when 'be'
    last_response.should have_selector("td:contains('#{name}')")
  when 'not be'
    last_response.should_not have_selector("td:contains('#{name}')")
  end

end

When /^I press delete on "([^\"]*)"$/ do |bin|
  pending
end

Given /^that stash bin is (empty|not empty)$/ do |contents|

  case contents
  when 'empty' then @the_bin.should be_empty

  when 'not empty'
    step "an idle wip"
    step "I goto its wip page"
    step %Q(I choose "stash")
    step %Q(I select "#{@the_bin.name}")
    step %Q(I press "Update")
    step "the response should be OK"
  end

end

Then /^the stashspace should have (\d+) wips$/ do |count|
  doc = Nokogiri::HTML last_response.body
  trs = doc / '#results tr'
  (trs.reject { |tr| tr % 'th'}).size.should == count.to_i
end

