Given /^a stash bin named "([^\"]*)"$/ do |name|
  Given %Q(I goto "/stashspace")
  And %Q(I fill in "name" with "default bin")
  When %Q(I press "Create")
  Then 'I should be redirected to "/stashspace"'
  last_response.should be_ok
  @the_bin = Daitss.archive.stashspace.find { |b| b.name == name }
  @the_bin.should_not be_nil
end

Given /^a stash bin named "([^\"]*)" with (\d+) package$/ do |name, count|
  Given %Q(a stash bin named "#{name}")
  Given "#{count} idle wips"
  Given %Q(I goto "/workspace")
  When %Q(I choose "stash")
  When %Q(I select "#{@the_bin.name}")
  When %Q(I press "Update")
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
    Given "an idle wip"
    And "I goto its wip page"
    When %Q(I choose "stash")
    And %Q(I select "#{@the_bin.name}")
    And %Q(I press "Update")
    And "the response should be OK"
  end

end
