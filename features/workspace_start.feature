Feature: start
  To start non-running wips

  Scenario: one non-running sip
    Given an idle wip
    And I goto "/workspace"
    When I choose "start"
    And I press "Update"
    Then there should be 1 running wips

  Scenario: mix of running and non-running
    Given an idle wip
    And a running wip
    And I goto "/workspace"
    When I choose "start"
    And I press "Update"
    Then there should be 2 running wips
