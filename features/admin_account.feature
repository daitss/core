Feature: admin of accounts
  To be able to add & remove accounts

  Scenario: add a new stash bin
    Given I goto "/admin"
    And I fill in "new-account" with "TESTADD"
    When I press "Create Account"
    Then there should be an account named "TESTADD"

  Scenario: remove an empty account
    Given a account named "TESTRM"
    And that account is empty
    And I goto "/admin"
    When I press "Delete"
    Then there should not be a account named "TESTRM"

  Scenario: remove a non-empty account
    Given a account named "TESTRM"
    And that account is not empty
    And I goto "/admin"
    When I press "Delete"
    Then the response should be NG
    Then the response contains "cannot delete a non-empty account"
