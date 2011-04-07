Feature: start
  To start non-running wips

  Scenario: one non-running sip
    Given an idle wip
    And I goto "/workspace"
    When I choose "start"
    And I press "Update"
    Then I should be redirected
    And there should be 1 running wips

  Scenario: with a note
    Given an idle wip
    And I goto "/workspace"
    When I choose "start"
    And I fill in "note" with "lorem ipsum"
    And I press "Update"
    Then I should be redirected
    And it should have an "ingest started" event with note "lorem ipsum"

  Scenario: mix of running and non-running
    Given an idle wip
    And a running wip
    And I goto "/workspace"
    When I choose "start"
    And I press "Update"
    Then I should be redirected
    And there should be 2 running wips
