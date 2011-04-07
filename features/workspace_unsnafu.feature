Feature: unsnafu
  To unsnafu snafu wips

  Scenario: no snafu wips
    Given an idle wip
    And I goto "/workspace"
    When I choose "unsnafu"
    And I press "Update"
    Then I should be redirected to "/workspace"
    And there should be 0 snafu wips

  Scenario: some snafu wips
    Given a snafu wip
    And I goto "/workspace"
    When I choose "unsnafu"
    And I press "Update"
    Then I should be redirected to "/workspace"
    And there should be 0 snafu wips

  Scenario: with a note
    Given an snafu wip
    And I goto "/workspace"
    When I choose "unsnafu"
    And I fill in "note" with "lorem ipsum"
    And I press "Update"
    Then I should be redirected to "/workspace"
    And there should be 0 snafu wips
    And it should have an "ingest unsnafu" event with note like "lorem ipsum"


  Scenario: some snafu wips with a note
    Given a snafu wip
    And I goto "/workspace"
    When I choose "unsnafu"
    And I press "Update"
    And I fill in "note" with "lorem ipsum"
    Then I should be redirected to "/workspace"
    And there should be 0 snafu wips
    And it should have an "ingest stopped" event with note "lorem ipsum"
