Feature: admin of accounts
  To be able to add & remove accounts

  Scenario: add a new account
    Given I goto "/admin"
    And I fill in the account form with:
      | code | name     |
      | ADD  | add test |
    When I press "Create Account"
    Then there should be an account with:
      | code | name     |
      | ADD  | add test |

  Scenario: remove an empty account
    Given a account named "test rm"
    And that account is empty
    And I goto "/admin"
    When I press "Delete" for the account
    Then there should not be a account named "test rm"

  Scenario: remove a non-empty account
    Given a account named "test rm non empty"
    And that account is not empty
    And I goto "/admin"
    When I press "Delete" for the account
    Then the response should be NG
    Then the response contains "cannot delete a non-empty account"
