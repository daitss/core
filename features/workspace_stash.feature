Feature: stash
  To stash a non-running wip

  Scenario: one non-running sip should disappear from the workspace
    Given a workspace with 1 idle wip
    And a stash bin named "default bin"
    And I goto "/workspace"
    When I choose "stash"
    And I select "default bin"
    And I press "Update"
    Then there should be 0 wips

  Scenario: one non-running sip should show up in the stash bin
    Given a workspace with 1 idle wip
    And a stash bin named "default bin"
    And I goto "/workspace"
    When I choose "stash"
    And I select "default bin"
    And I press "Update"
    And I goto "/stash"
    And I click on "default bin"
    Then I should see the wip in the stash bin
