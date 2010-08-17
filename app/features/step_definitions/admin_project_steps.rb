Given /^I fill in the project form with:$/ do |table|

  within "form#create-project" do

    table.hashes.each do |row|

      row.each do |field, value|

        if field == 'account'
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

Given /^a project named "([^"]*)"$/ do |name|
  Given 'I goto "/admin"'
  And 'a account coded "ACTPRJ"'
  code = name.upcase.tr(' ', '')

  within "form#create-project" do
    fill_in "code", :with => code
    fill_in "name", :with => name
    select "ACTPRJ", :from => 'account'
  end

  When 'I press "Create Project"'
  last_response.should be_ok
  @the_project = Project.first :code => code
  @the_project.should_not be_nil
end

Given /^that project (is|is not) empty$/ do |condition|

  if condition == 'is'
    @the_project.submitted_sips.should be_empty
  else
    s = SubmittedSip.new
    s.package_name = 'FOO'
    s.package_size = 10
    s.number_of_datafiles = 10
    s.ieid = 'E1024'

    @the_project.submitted_sips << s
    @the_project.save.should be_true
    @the_project.submitted_sips.should_not be_empty
  end

end

When /^I press "([^"]*)" for the project$/ do |button|

  within "tr:contains('#{@the_project.code}')" do
    click_button button
  end

end

Then /^there should not be a project named "([^"]*)"$/ do |name|
  last_response.should_not have_selector("td:contains('#{name}')")
end
