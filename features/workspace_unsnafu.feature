Feature: unsnafu all
  To unsnafu all snafu wips

  Scenario: no snafu wips
    Given a workspace with 1 idle wip
    And I goto "/workspace"
    When I choose "unsnafu all"
    And I press "Update"
    Then there should be 0 snafu wips

  Scenario: some snafu wips
    Given a workspace with 1 snafu wip
    And I goto "/workspace"
    When I choose "unsnafu all"
    And I press "Update"
    Then there should be 0 snafu wips
