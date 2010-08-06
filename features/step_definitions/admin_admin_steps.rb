Given /^I fill in the account form with:$/ do |table|

  table.hashes.each do |row|

    row.each do |field, value|
      fill_in "account-#{field}", :with => value
    end

  end

end

Then /^there should be an account with:$/ do |table|

  table.hashes.each do |row|
    cell_conditions = row.values.map { |v| "td = '#{v}'"}.join ' and '
    last_response.should have_xpath("//tr[#{cell_conditions}]")
  end

end

Given /^a account named "([^"]*)"$/ do |name|
  Given 'I goto "/admin"'
  code = name.upcase.tr(' ', '')
  fill_in "account-code", :with => code
  fill_in "account-name", :with => name
  When 'I press "Create Account"'
  last_response.should be_ok
  @the_account = Account.first :code => code
  @the_account.should_not be_nil
end

Given /^that account (is|is not) empty$/ do |condition|

  if condition == 'is'
    @the_account.projects.should be_empty
  else
    p = Project.new
    p.name = "the project name";
    p.code = "TPN"
    @the_account.projects << p
    @the_account.save.should be_true
    @the_account.projects.should_not be_empty
  end

end

When /^I press "([^"]*)" for the account$/ do |button|

  within "tr:contains('#{@the_account.code}')" do
    click_button button
  end

end

Then /^there should not be a account named "([^"]*)"$/ do |name|
  last_response.should_not have_selector("td:contains('#{name}')")
end
