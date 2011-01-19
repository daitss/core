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

  Scenario: modify account
    Given I goto "/admin/accounts"
    When I click on "modify account"
    And I fill in the account update form with:
      | description | report-email |
      | updated  | foo@host.com   |
    And I press "modify account"
    Then I should be redirected
    And there should be an account with:
      | id | description | report-email |
      | ACT | updated | foo@host.com |
    And there should be an admin log entry:
      | user | message          |
      | foo  | updated account: ACT |

  Scenario: should get 404 if you try to modify non-existant account 
    Given I goto "/admin/accounts/foobar"
    Then the response code should be 404

