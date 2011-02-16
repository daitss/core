Feature: Manage users
  In order to add users
  an operator
  wants to register, and modify users

  Scenario: navigate to the users page
    Given I am on the home page
    When I follow "users"
    Then I should be on the users page

  Scenario: Register new user
    Given I am on the users page
    And I follow "add user"
    And I am on the new user page
    When I select "OPERATIONS" from "Account"
    And I fill in "Id" with "hermes"
    And I fill in "Description" with "a bureaucrat"
    And I fill in "First name" with "Hermes"
    And I fill in "Last name" with "Conrad"
    And I fill in "Email" with "hermes.conrad@planetexpress.com"
    And I fill in "Phone" with "999 555 1212"
    And I fill in "Address" with "1432 New New York"
    And I check "Is admin contact"
    And I check "Is tech contact"
    And I press "Save User"
    Then I should be on hermes's user page

  Scenario: List users
    Given 15 arbitrary users
    When I am on the users page
    Then I should see all the arbitrary users

  Scenario: List inactive users
    Given a user "hermes"
    And user "hermes" is inactive
    When I am on the users page
    And I follow "inactive users"
    Then I should see "hermes"

  Scenario: List active users
    Given a user "hermes"
    And user "hermes" is inactive
    When I am on the users page
    And I follow "inactive users"
    And I follow "active users"
    Then I should not see "hermes"

  Scenario: View a user
    Given a user "hermes"
    And I am on the users page
    When I follow "hermes"
    Then I should be on hermes's user page
    And I should see "hermes"

  Scenario: Modify a user
    Given a user "hermes"
    And I am on hermes's user page
    And I follow "edit profile"
    When I fill in "Email" with "hcon@planetexpress.com"
    And I press "Update User"
    Then I should be on hermes's user page
    And I should see "user hermes updated" within ".notice"
    And I should see "hcon@planetexpress.com"

  Scenario: Deactivate user
    Given a user "hermes"
    And I am on hermes's user page
    When I follow "edit profile"
    And I uncheck "Active"
    And I press "Update User"
    Then I should see "user hermes updated" within ".notice"
    And I am on the users page
    And I should not see "hermes"

  Scenario: Deactivate user
    Given a user "hermes"
    And user "hermes" is inactive
    And I am on hermes's user page
    When I follow "edit profile"
    And I check "Active"
    And I press "Update User"
    Then I should see "user hermes updated" within ".notice"
    And I am on the users page
    And I should see "hermes"

