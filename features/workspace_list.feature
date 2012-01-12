Feature: list wips
  To manage the processing of information packages
  An operator should be able to to view wips in the workspace

  Scenario: listing with states
    Given a workspace with the following wips:
      | count |   state |
      |     2 |    idle |
      |     1 | running |
      |     1 |   snafu |
      |     1 | stopped |
    When I goto "/workspace"
    Then there should be 2 idle wips listed in the table
    Then there should be the following wips:
      | count |   state |
      |     1 | running |
      |     1 |   snafu |
      |     1 | stopped |

  Scenario Outline: listing
    Given <quantity> wips
    When I goto "/workspace"
    Then there should be <quantity> idle wips listed in the table

    Examples:
      | quantity |
      |        2 |
      |        5 |

  Scenario: listing idles
    When I goto "/workspace"
    Then the idle table should be zeroed out

  Scenario Outline: Filter by date
    Given 1 stopped wips
    Given I goto "/workspace"
    When I fill in "start_date" with "<start_date>"
    And I fill in "end_date" with "<end_date>"
    And I press "Set Scope"
    Then I should have <count> wips in the results
    Examples:
      |start_date|end_date|count|
      |3/15/2011|3/16/2011|0|
      |3/15/2011||1|
      ||3/17/2011|0|
      |||1|

  Scenario Outline: Filter by batch
    Given 1 stopped wips in batch "foo"
    Given 1 stopped wips
    And a batch "nopackages"
    Given I goto "/workspace"
    When I select batch "<batch>"
    And I press "Set Scope"
    Then I should have <count> wips in the results
    Examples:
      |batch|count|
      |foo|1|
      |nopackages|0|

  Scenario Outline: Filter by account
    Given 1 stopped wips under account/project "FDA-FDA"
    Given 1 stopped wips under account/project "FDA-PRB"
    Given 1 stopped wips under account/project "UF-UF"
    Given 1 stopped wips under account/project "UF-FHP"
    Given an account/project "FOO-BAR"
    Given I goto "/workspace"
    When I select account "<account>"
    And I press "Set Scope"
    Then I should have <count> wips in the results
    Examples:
      |account|count|
      |FDA|2|
      |UF|2|
      |FOO|0|

  Scenario Outline: Filter by project
    Given 1 stopped wips under account/project "FDA-FDA"
    Given 1 stopped wips under account/project "FDA-PRB"
    Given an account/project "FOO-BAR"
    Given I goto "/workspace"
    When I select project "<project>"
    And I press "Set Scope"
    Then I should have <count> wips in the results
    Examples:
      |project|count|
      |FDA-FDA|1|
      |PRB-FDA|1|
      |BAR-FOO|0|

  # 1/12/2011 made pending, this test fails non-deterministcally
  Scenario Outline: Filter by state
    Given this test is pending
    Given a snafu wip
    Given a stop wip
    Given a running wip
    Given a dead wip
    And I goto "/workspace"
    When I select status "<activity>"
    And I press "Set Scope"
    Then I should have <count> wips in the results
    Examples:
      |activity|count|
      |running|1|
      |dead|1|
      |error|1|
      |stopped|1|

  Scenario: Workspace wide actions after scope should not affect entire workspace
    Given a idle wip
    Given a idle wip
    Given a dead wip
    And a stash bin named "default bin"
    And I goto "/workspace"
    When I select status "idle"
    And I press "Set Scope"
    And I choose "stash"
    And I press "Update"
    And I goto "/stashspace/default%20bin"
    Then the stashspace should have 2 wips

  Scenario: Workspace wide actions after scope should not affect entire workspace
    Given a idle wip
    Given a idle wip
    Given a dead wip
    And a stash bin named "default bin"
    And I goto "/workspace"
    When I select status "idle"
    And I press "Set Scope"
    And I choose "stash"
    And I press "Update"
    And I goto "/workspace"
    Then I should have 1 wips in the results

  Scenario: Workspace wide actions after scope should not affect entire workspace
    Given 2 snafu wips in batch "foo"
    Given a snafu wip
    Given a snafu wip
    And I goto "/workspace"
    When I select batch "foo"
    And I press "Set Scope"
    And I choose "reset"
    And I press "Update"
    And I goto "/workspace"
    Then there should be 2 idle wips listed in the table
    And there should be 2 snafu wips

  Scenario: Workspace wide actions after scope should not affect entire workspace
    Given 1 stopped wips in batch "foo"
    Given a stop wip
    Given a stop wip
    And I goto "/workspace"
    When I select batch "foo"
    And I press "Set Scope"
    And I choose "start"
    And I press "Update"
    And I goto "/workspace"
    Then there should be 1 running wip
    And there should be 2 stopped wips

  Scenario: Workspace should display total size of wips
    Given 2 stopped wips
    When I goto "/workspace"
    Then I should see "58.70 KB"

