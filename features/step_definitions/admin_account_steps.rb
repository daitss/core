Given /^I fill in the account form with:$/ do |table|

  within "form#create-account" do

    table.hashes.each do |row|

      row.each do |field, value|
        fill_in field, :with => value
      end

    end

  end

end

Then /^there should be an account with:$/ do |table|

  table.hashes.each do |row|
    cell_conditions = row.values.map { |v| "td = '#{v}'"}.join ' and '
    last_response.should have_xpath("//tr[#{cell_conditions}]")
  end

end

Given /^a account "([^"]*)"$/ do |name|
  Given 'I goto "/admin"'
  id = name.upcase.tr(' ', '')

  within "form#create-account" do
    fill_in "id", :with => id
    fill_in "description", :with => "#{id} #{id} #{id}".downcase
  end

  When 'I press "Create Account"'
  Then 'I should be redirected to "/admin"'
  last_response.should be_ok
  @the_account = Account.get id
  @the_account.should_not be_nil
end

Given /^that account (is|is not) empty$/ do |condition|

  if condition == 'is'
    @the_account.projects.should == [@the_account.default_project]
  else
    p = Project.new
    p.description = "the project name";
    p.id = "TPN"
    @the_account.projects << p
    @the_account.save.should be_true
    @the_account.projects.should_not be_empty
  end

end

When /^I press "([^"]*)" for the account$/ do |button|

  within "tr:contains('#{@the_account.id}')" do
    click_button button
  end

end

Then /^there should not be a account "([^"]*)"$/ do |name|
  last_response.should_not have_selector("td:contains('#{name}')")
end
