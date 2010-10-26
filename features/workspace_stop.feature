Feature: stop
  To stop running wips

  Scenario: one running sip
    Given a running wip
    And I goto "/workspace"
    When I choose "stop"
    And I press "Update"
    Then I should be redirected
    And there should be 0 running wips
    And there should be 1 stopped wips

  Scenario: mix of running and non-running
    Given 2 idle wips
    And 2 running wip
    And I goto "/workspace"
    When I choose "stop"
    And I press "Update"
    Then I should be redirected
    And there should be 0 running wips
    And there should be 2 stopped wips
