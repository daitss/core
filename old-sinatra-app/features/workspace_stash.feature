Feature: stash
  To stash a non-running wip

  Scenario: one non-running sip should disappear from the workspace
    Given an idle wip
    And a stash bin named "default bin"
    And I goto "/workspace"
    When I choose "stash"
    And I select "default bin"
    And I press "Update"
    Then I should be redirected
    And there should be 0 wips

  Scenario: one non-running sip should show up in the stash bin
    Given an idle wip
    And a stash bin named "default bin"
    And I goto "/workspace"
    When I choose "stash"
    And I select "default bin"
    And I press "Update"
    And I goto "/stashspace"
    And I click on "default bin"
    Then I should see the wip in the stash bin
