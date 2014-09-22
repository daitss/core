Given /^I fill in the account form with:$/ do |table|

  page.within "form#create-account" do
    
    table.hashes.each do |row|

      row.each do |field, value|
        fill_in field, :with => value
      end
    end
  end
end

Given /^I fill in the account update form with:$/ do |table|

  page.within "form#modify-account" do

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
    page.body.should have_xpath("//tr[#{cell_conditions}]")
  end

end

Given /^a account "([^"]*)"$/ do |name|
  step 'I goto "/admin/accounts"'
  id = name.upcase.tr(' ', '')

  page.within "form#create-account" do
    fill_in "id", :with => id
    fill_in "description", :with => "#{id} #{id} #{id}".downcase
  end

  step 'I press "Create Account"'
  step 'I should be redirected to "/admin/accounts"'
  (200..399).should include(page.status_code)
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
    @the_account.save.should be true
    @the_account.projects.should_not be_empty
  end

end

When /^I press "([^"]*)" for the account$/ do |button|

  page.within "tr:contains('#{@the_account.id}')" do
    click_button button
  end

end

Then /^there should not be a account "([^"]*)"$/ do |name|
  page.should_not have_selector("td:contains('#{name}')")
end
