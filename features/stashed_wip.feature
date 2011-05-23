Feature: modifying the status of a stashed wip

  Scenario: unstash a wip
    Given a stash bin named "default bin" with 1 package
    And I goto "/stashspace"
    And I click on "default bin"
    And I click on the stashed wip
    When I choose "unstash"
    And I press "Update"
    Then I should be redirected
    And I should be at the wip page
    And it should have an "unstash" event by agent "operator"

  Scenario: unstash a wip with a note
    Given a stash bin named "default bin" with 1 package
    And I goto "/stashspace"
    And I click on "default bin"
    And I click on the stashed wip
    When I choose "unstash"
    And I fill in "note" with "stash it!"
    And I press "Update"
    Then I should be redirected
    And it should have an "unstash" event with note "stash it!"

  Scenario: abort a wip
    Given a stash bin named "default bin" with 1 package
    And I goto "/stashspace"
    And I click on "default bin"
    And I click on the stashed wip
    When I choose "abort"
    And I fill in "note" with "abort it!"
    And I press "Update"
    Then I should be redirected
    And I should be at the package page
    And the response contains "abort it!"
    And the response contains "aborted"

  Scenario: abort a wip without a note
    Given a stash bin named "default bin" with 1 package
    And I goto "/stashspace"
    And I click on "default bin"
    And I click on the stashed wip
    When I choose "abort"
    And I press "Update"
    Then the response code should be 400
    Then the response contains "note required for abort"
