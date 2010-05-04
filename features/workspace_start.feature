Feature: start all
  To start all non-running wips

  Scenario: one non-running sip
    Given a workspace with 1 idle wip
    And I goto "/workspace"
    When I choose "start all"
    And I press "Update"
    Then there should be 1 running wips

  Scenario: mix of running and non-running
    Given a workspace
    And it has 1 idle wip
    And it has 1 running wip
    And I goto "/workspace"
    When I choose "start all"
    And I press "Update"
    Then there should be 2 running wips
