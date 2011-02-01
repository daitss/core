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
