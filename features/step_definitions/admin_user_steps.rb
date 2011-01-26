Given /^I fill in the user form with:$/ do |table|
  Given 'I goto "/admin/users"'

  within "form#create-user" do

    table.hashes.each do |row|

      row.each do |field, value|
        fill_in field, :with => value
      end
    end
  end
end

Given /^I fill in the user update form with:$/ do |table|
  within "form#modify-user" do

    table.hashes.each do |row|

      row.each do |field, value|
        fill_in field, :with => value
      end
    end
  end
end

Given /^I fill in the user password form with:$/ do |table|
  within "form#change-user-password" do

    table.hashes.each do |row|

      row.each do |field, value|
        fill_in field, :with => value
      end
    end
  end
end


When /^I select user type "([^\"]*)"$/ do |type|
  select type, :from => 'type'
end

Then /^there should be a user with:$/ do |table|

  table.hashes.each do |row|
    cell_conditions = row.values.map { |v| "td = '#{v}'"}.join ' and '
    last_response.should have_xpath("//tr[#{cell_conditions}]")
  end

end

Then /^there should not be a user with:$/ do |table|

  table.hashes.each do |row|
    cell_conditions = row.values.map { |v| "td = '#{v}'"}.join ' and '
    last_response.should_not have_xpath("//tr[#{cell_conditions}]")
  end
end

Given /^a user "([^"]*)"$/ do |id|
  Given 'I goto "/admin/users"'

  within "form#create-user" do
    fill_in 'id', :with => id
    fill_in 'first_name', :with => "#{id} first name"
    fill_in 'last_name', :with => "#{id}last name"
    fill_in 'email', :with => "#{id}@example.com"
    fill_in 'phone', :with => "555 1212"
    fill_in 'address', :with => "San Jose"
  end

  When 'I press "Create User"'
  Then 'I should be redirected'
  last_response.should be_ok
  @the_user = User.get id
  @the_user.should_not be_nil
end

Given /^a contact "([^"]*)"$/ do |id|
  Given 'I goto "/admin/users"'

  within "form#create-user" do
    select "affiliate", :from => "type"
    fill_in 'id', :with => id
    fill_in 'first_name', :with => "#{id} first name"
    fill_in 'last_name', :with => "#{id}last name"
    fill_in 'email', :with => "#{id}@example.com"
    fill_in 'phone', :with => "555 1212"
    fill_in 'address', :with => "San Jose"
  end

  When 'I press "Create User"'
  Then 'I should be redirected'
  last_response.should be_ok
  @the_user = User.get id
  @the_user.should_not be_nil
end

Given /^that user (is|is not) empty$/ do |condition|
  if condition == 'is'
    @the_user.events.should be_empty
  else
    p = Package.new
    p.project = @the_user.account.default_project
    p.sip = Sip.new
    p.sip.name = 'FOO'
    p.sip.size_in_bytes = 10
    p.sip.number_of_datafiles = 10
    p.uri = "daitss-test://#{p.id}"

    e = Event.new
    e.name = 'test event'
    e.timestamp = Time.now
    e.package = p

    @the_user.events << e
    @the_user.save.should be_true
  end
end

When /^I press "([^"]*)" for the user$/ do |button|

  within "tr:contains('#{@the_user.id}')" do
    click_button button
  end

end

Then /^there should not be a user "([^"]*)"$/ do |id|
  last_response.should_not have_selector("td:contains('#{id}')")
end

Then /^user "([^"]*)" should authenticate with password "([^"]*)"$/ do |user, pass|
  u = User.get(user)
  raise "user #{user} not found" unless u
  raise "user #{user} did not authenticate with password #{pass}" unless u.authenticate(pass)
end

