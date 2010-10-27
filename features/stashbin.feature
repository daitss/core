Feature: stash bins
  To be able to add & remove bins

  Scenario: add a new stash bin
    Given I goto "/stashspace"
    And I fill in "name" with "default bin"
    When I press "Create"
    Then I should be redirected
    And there should be a stash bin named "default bin"
    And there should be an admin log entry:
      | user | message                    |
      | foo  | new stash bin: default bin |

  Scenario: remove an empty stash bin
    Given a stash bin named "default bin"
    And that stash bin is empty
    And I goto "/stashspace"
    When I press "Delete"
    Then there should not be a stash bin named "default bin"
    And there should be an admin log entry:
      | user | message                       |
      | foo  | delete stash bin: default bin |

  Scenario: remove a non-empty stash bin
    Given a stash bin named "default bin"
    And that stash bin is not empty
    When I goto "/stashspace"
    Then I cannot press "Delete"
