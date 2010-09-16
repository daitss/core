Given /^a stash bin named "([^\"]*)"$/ do |name|
  @the_bin = StashBin.new :name => name
  @the_bin.save or raise "could not save stashbin"
end

Given /^I fill in the stashbin form with:$/ do |table|

  within "form#create-stashbin" do

    table.hashes.each do |row|

      row.each do |field, value|
        fill_in field, :with => value
      end

    end

  end

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
  when 'empty'
    pattern = File.join @the_bin.path, '*'
    FileUtils.rm_rf Dir[pattern]

  when 'not empty'
    Given "an idle wip"
    And "I goto its wip page"
    When %Q(I choose "stash")
    And %Q(I select "#{@the_bin.name}")
    And %Q(I press "Update")
  end

end
