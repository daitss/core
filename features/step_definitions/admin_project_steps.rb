Given /^I fill in the project form with:$/ do |table|

  within "form#create-project" do

    table.hashes.each do |row|

      row.each do |field, value|

        if field == 'account_id'
          select value, :from => field
        else
          fill_in field, :with => value
        end

      end

    end

  end

end

Then /^there should be an project with:$/ do |table|

  table.hashes.each do |row|
    cell_conditions = row.values.map { |v| "td = '#{v}'"}.join ' and '
    last_response.should have_xpath("//tr[#{cell_conditions}]")
  end

end

Given /^a project "([^"]*)"$/ do |id|
  account_id = 'ACTPRJ'
  Given 'I goto "/admin"'
  And "a account \"#{account_id}\""

  within "form#create-project" do
    fill_in "id", :with => id
    fill_in "description", :with => "#{id} #{id} #{id}".downcase
    select account_id, :from => 'account_id'
  end

  When 'I press "Create Project"'
  last_response.should be_ok
  @the_project = Account.get(account_id).projects.first :id => id
  @the_project.should_not be_nil
end

Given /^that project (is|is not) empty$/ do |condition|

  if condition == 'is'
    @the_project.packages.should be_empty
  else
    p = Package.new
    p.sip = Sip.new
    p.uri = "daitss-test://#{p.id}"
    p.sip.name = 'FOO'
    p.sip.size_in_bytes = 10
    p.sip.number_of_datafiles = 10

    @the_project.packages << p
    @the_project.save.should be_true
    @the_project.packages.should_not be_empty
  end

end

When /^I press "([^"]*)" for the project$/ do |button|

  within "tr:contains('#{@the_project.id}')" do
    click_button button
  end

end

Then /^there should not be a project "([^"]*)"$/ do |id|
  last_response.should_not have_selector("td:contains('#{id}')")
end
