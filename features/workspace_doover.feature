Feature: do over
  Reset the journal for a wip so that processing starts over

  Scenario: do over
    Given a running wip
    And I goto "/workspace"
    When I choose "do over"
    When I fill in "note" with "lorem ipsum"
    And I press "Update"
    Then I should be redirected
    And it should have an "ingest do over" event with note like "lorem ipsum"
    And the journal file for the wip should be empty
