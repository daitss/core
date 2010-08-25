Given /^I fill in the user form with:$/ do |table|

  within "form#create-user" do

    table.hashes.each do |row|

      row.each do |field, value|
        fill_in field, :with => value
      end

    end

  end

end

Then /^there should be a user with:$/ do |table|

  table.hashes.each do |row|
    cell_conditions = row.values.map { |v| "td = '#{v}'"}.join ' and '
    last_response.should have_xpath("//tr[#{cell_conditions}]")
  end

end

Given /^a user named "([^"]*)"$/ do |name|
  Given 'I goto "/admin"'

  within "form#create-user" do
    fill_in 'username', :with => name
    fill_in 'first_name', :with => "#{name} first name"
    fill_in 'last_name', :with => "#{name}last name"
    fill_in 'email', :with => "#{name}@example.com"
    fill_in 'phone', :with => "555 1212"
    fill_in 'address', :with => "San Jose"
  end

  When 'I press "Create User"'
  last_response.should be_ok
  @the_user = User.first :identifier => name
  @the_user.should_not be_nil
end

Given /^that user (is|is not) empty$/ do |condition|
  if condition == 'is'
    @the_user.operations_events.should be_empty
  else
    s = Sip.new
    s.name = 'FOO'
    s.size_in_bytes = 10
    s.number_of_datafiles = 10
    s.id = 'E1024'

    e = Event.new
    e.event_name = 'test event'
    e.timestamp = Time.now
    #e.operations_agent = Program.system_agent
    e.sip = s

    @the_user.operations_events << e
    @the_user.save.should be_true
  end
end

When /^I press "([^"]*)" for the user$/ do |button|

  within "tr:contains('#{@the_user.identifier}')" do
    click_button button
  end

end

Then /^there should not be a user named "([^"]*)"$/ do |name|
  last_response.should_not have_selector("td:contains('#{name}')")
end
