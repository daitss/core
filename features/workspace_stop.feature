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

  Scenario: with a note
    Given a running wip
    And I goto "/workspace"
    When I choose "stop"
    And I fill in "note" with "lorem ipsum"
    And I press "Update"
    Then I should be redirected
    And there should be 0 running wips
    And there should be 1 stopped wips
    And it should have an "ingest stopped" event with note "lorem ipsum"

  Scenario: mix of running and non-running
    Given 2 idle wips
    And 2 running wip
    And I goto "/workspace"
    When I choose "stop"
    And I press "Update"
    Then I should be redirected
    Then there should be 0 running wips
    Then there should be 2 stopped wips

  Scenario: ops event written on stop
    Given a running wip
    And I goto "/workspace"
    When I choose "stop"
    And I press "Update"
    And I goto its package page
    Then there should be an "ingest stopped" event

  Scenario: wip stop should log the right user
    Given a running wip
    And I goto "/workspace"
    When I choose "stop"
    And I press "Update"
    And I goto its wip page
    And it should have an "ingest stopped" event by agent "operator"

  Scenario: wip start should log the right user
    Given an running wip
    And I goto its wip page
    When I choose "stop"
    And I press "Update"
    And I goto its wip page
    And it should have an "ingest stopped" event by agent "operator"
 
