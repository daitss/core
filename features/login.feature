@loggedout
Feature: Login
  In order to authenticate
  operator and affiliate
  want an interface to login and logout

  Scenario: redirect to /login
    When I go to the home page
    Then I should be on the login page
    And I should see "please login" within ".notice.alert"

  Scenario: logging in
    Given I go to the login page
    When I fill in "User" with "root"
    And I fill in "Password" with "root"
    And I press "login"
    Then I should be on the home page
    And I should see "welcome root" within ".notice"

  Scenario: logging in when inactive
    Given I go to the login page
    And user "root" is inactive
    When I fill in "User" with "root"
    And I fill in "Password" with "root"
    And I press "login"
    Then I should be on the login page
    And I should see "invalid credentials" within ".alert"

  Scenario: logging in with wrong user id
    Given I go to the login page
    And user "root" is inactive
    When I fill in "User" with "rOOt"
    And I fill in "Password" with "root"
    And I press "login"
    Then I should be on the login page
    And I should see "invalid credentials" within ".alert"

  Scenario: logging in with wrong password
    Given I go to the login page
    And user "root" is inactive
    When I fill in "User" with "root"
    And I fill in "Password" with "r00t"
    And I press "login"
    Then I should be on the login page
    And I should see "invalid credentials" within ".alert"

  Scenario: logging out
    Given I am logged in
    When I go to the home page
    And I follow "logout root"
    Then I should be on the login page
    And I should see "goodbye root" within ".notice"