Feature: admin of stashspace
  To be able to add & remove bins

  Scenario: add a new stash bin
    Given I goto "/admin"
    And I fill in the stashbin form with:
      | name        |
      | default bin |
    When I press "Create Stash Bin"
    Then there should be a stash bin named "default bin"
    And there should be an admin log entry:
      | user | message                    |
      | foo  | new stash bin: default bin |

  Scenario: remove an empty stash bin
    Given a stash bin named "default bin"
    And that stash bin is empty
    And I goto "/admin"
    When I press "Delete"
    Then there should not be a stash bin named "default bin"
    And there should be an admin log entry:
      | user | message                       |
      | foo  | delete stash bin: default bin |

  Scenario: remove a non-empty stash bin
    Given a stash bin named "default bin"
    And that stash bin is not empty
    And I goto "/admin"
    When I press "Delete"
    Then the response should be NG
    Then the response contains "cannot delete a non-empty stash bin"
