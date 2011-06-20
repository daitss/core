Feature: stash bins
  To be able to add & remove bins

  Scenario: add a new stash bin
    Given I goto "/stashspace"
    And I fill in "name" with "default bin"
    When I press "Create"
    Then I should be redirected
    And there should be a stash bin named "default bin"
    And there should be an admin log entry:
      | user | message                    |
      | foo  | new stash bin: default bin |

  Scenario: remove an empty stash bin
    Given a stash bin named "default bin"
    And that stash bin is empty
    And I goto "/stashspace"
    When I press "Delete"
    Then there should not be a stash bin named "default bin"
    And there should be an admin log entry:
      | user | message                       |
      | foo  | delete stash bin: default bin |

  Scenario: remove a non-empty stash bin
    Given a stash bin named "default bin"
    And that stash bin is not empty
    When I goto "/stashspace"
    Then I cannot press "Delete"

  Scenario: unstash all
    Given a stash bin named "default bin"
    And that stash bin is not empty
    When I goto "/stashspace"
    And I click on "default bin"
    And I press "unstash all"
    Then I should be redirected to "/stashspace/default%20bin"
    And I should see no stashed packages

  Scenario Outline: Filter by date
    Given a stash bin named "default bin"
    And 1 stopped wips
    And I stash it in "default bin"
    And I goto "/stashspace"
    And I click on "default bin"
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
    Given a stash bin named "default bin"
    Given 1 stopped wips in batch "foo"
    And I stash it in "default bin"
    Given 1 stopped wips
    And I stash it in "default bin"
    And a batch "nopackages"
    And I goto "/stashspace"
    And I click on "default bin"
    When I select batch "<batch>"
    And I press "Set Scope"
    Then I should have <count> wips in the results
    Examples:
      |batch|count|
      |foo|1|
      |nopackages|0|

  Scenario Outline: Filter by account
    Given a stash bin named "default bin"
    Given 1 stopped wips under account/project "FDA-FDA"
    And I stash it in "default bin"
    Given 1 stopped wips under account/project "FDA-PRB"
    And I stash it in "default bin"
    Given 1 stopped wips under account/project "UF-UF"
    And I stash it in "default bin"
    Given 1 stopped wips under account/project "UF-FHP"
    And I stash it in "default bin"
    Given an account/project "FOO-BAR"
    Given I goto "/stashspace"
    And I click on "default bin"
    When I select account "<account>"
    And I press "Set Scope"
    Then I should have <count> wips in the results
    Examples:
      |account|count|
      |FDA|2|
      |UF|2|
      |FOO|0|

  Scenario Outline: Filter by project
    Given a stash bin named "default bin"
    Given 1 stopped wips under account/project "FDA-FDA"
    And I stash it in "default bin"
    Given 1 stopped wips under account/project "FDA-PRB"
    And I stash it in "default bin"
    Given an account/project "FOO-BAR"
    Given I goto "/stashspace"
    And I click on "default bin"
    When I select project "<project>"
    And I press "Set Scope"
    Then I should have <count> wips in the results
    Examples:
      |project|count|
      |FDA-FDA|1|
      |PRB-FDA|1|
      |BAR-FOO|0|

  Scenario Outline: Filter by state
    Given a stash bin named "default bin"
    Given a snafu wip
    And I stash it in "default bin"
    Given a idle wip
    And I stash it in "default bin"
    Given a stop wip
    And I stash it in "default bin"
    Given a dead wip
    And I stash it in "default bin"
    Given I goto "/stashspace"
    And I click on "default bin"
    When I select status "<activity>"
    And I press "Set Scope"
    Then I should have <count> wips in the results
    Examples:
      |activity|count|
      |running|0|
      |dead|1|
      |idle|1|
      |error|1|
      |stopped|1|







