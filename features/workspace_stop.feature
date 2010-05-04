Feature: stop all
  To stop all running wips

  Scenario: one running sip
    Given a workspace with 1 running wip
    And I goto "/workspace"
    When I choose "stop all"
    And I press "Update"
    Then there should be 0 running wips

  Scenario: mix of running and non-running
    Given a workspace
    And it has 2 idle wips
    And it has 2 running wips
    And I goto "/workspace"
    When I choose "stop all"
    And I press "Update"
    Then there should be 0 running wips
