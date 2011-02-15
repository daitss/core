Feature: Manage users
  In order to add users
  an operator
  wants to register, and modify users

  Scenario: Register new user
    Given I am on the new user page
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

  Scenario: View a user
    Given a user "hermes"
    When I go to hermes's user page
    Then I should see "hermes"

  #Scenario: Delete user
    #Given the following users:
    #|id|first_name|last_name|
    #||
    #||
    #||
    #||
    #When I delete the 3rd user
    #Then I should see the following users:
    #||
    #||
    #||
    #||

    #Scenario: deactivate a user
    #Scenario: activate a user
