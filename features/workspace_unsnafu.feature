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

  Scenario: wip unsnafu should log the right user
    Given a snafu wip
    And I goto "/workspace"
    When I choose "unsnafu"
    And I press "Update"
    And I goto its wip page
    And it should have an "ingest unsnafu" event by agent "operator"

  Scenario: wip unsnafu should log the right user
    Given an snafu wip
    And I goto its wip page
    When I choose "unsnafu"
    And I press "Update"
    And I goto its wip page
    And it should have an "ingest unsnafu" event by agent "operator"

