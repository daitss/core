Feature: stop all
  To stop all running wips

  Scenario: one running sip
    Given an empty workspace
    And I goto "/workspace"
    And I submit a sip
    And I choose "start all"
    And I press "Update"
    When I choose "stop all"
    And I press "Update"
    Then there should be 0 running sips

  Scenario: mix of running and non-running
    Given an empty workspace
    And I goto "/workspace"
    And I submit 2 sips
    And I choose "start all"
    And I press "Update"
    When I choose "stop all"
    And I press "Update"
    And I submit a sip
    Then there should be 0 running sips
