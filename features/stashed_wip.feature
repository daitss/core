Feature: modifying the status of a stashed wip

  Scenario: unstash a wip
    Given a stash bin named "default bin" with 1 package
    And I goto "/stashspace"
    And I click on "default bin"
    And I click on the stashed wip
    When I choose "unstash"
    And I press "Update"
    Then I should be at the wip page

  Scenario: abort a wip
    Given a stash bin named "default bin" with 1 package
    And I goto "/stashspace"
    And I click on "default bin"
    And I click on the stashed wip
    When I choose "abort"
    And I press "Update"
    Then I should be at the package page
    And the response contains "Abort"
