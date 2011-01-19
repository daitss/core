Feature: admin of accounts
  To be able to add & remove accounts

  Scenario: add a new account
    Given I goto "/admin/accounts"
    And I fill in the account form with:
      | id | description |
      | ADD  | add test  |
    When I press "Create Account"
    Then I should be redirected to "/admin/accounts"
    And there should be an account with:
      | id | description |
      | ADD  | add test  |
    And there should be an admin log entry:
      | user | message          |
      | foo  | new account: ADD |

  Scenario: remove an empty account
    Given a account "RM"
    And that account is empty
    And I goto "/admin/accounts"
    When I press "Delete" for the account
    Then I should be redirected to "/admin/accounts"
    And there should not be a account "RM"
    And there should be an admin log entry:
      | user | message            |
      | foo  | delete account: RM |

  Scenario: remove a non-empty account
    Given a account "RMNE"
    And that account is not empty
    And I goto "/admin/accounts"
    When I press "Delete" for the account
    Then I should not be redirected to "/admin/accounts"
    And the response should be NG
    And the response contains "cannot delete a non-empty account"
