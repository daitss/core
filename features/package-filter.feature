Feature: Filter recent activity

  Scenario Outline: Filter by date
    Given 4 packages ingested on "3/16/2011"
    Given 4 packages ingested on "2/16/2011"
    Given 4 packages ingested on "1/16/2011"
    Given I goto "/packages"
    When I fill in "start_date" with "<start_date>"
    And I fill in "end_date" with "<end_date>"
    And I press "Set Scope"
    Then I should have <count> package in the results
    Examples:
      |start_date|end_date|count|
      |3/15/2011|3/16/2011|4|
      |2/15/2011|2/16/2011|4|
      |3/15/2011||4|
      |2/15/2011||8|
      ||3/17/2011|12|
      |||12|
      |3/17/2011||0|
      ||1/1/2011|0|
      ||1/16/2011|4|

  Scenario Outline: Filter by batch
    Given 4 packages under batch "foo"
    Given 4 packages under batch "bar"
    And a batch "nopackages"
    Given I goto "/packages"
    When I select batch "<batch>"
    And I press "Set Scope"
    Then I should have <count> package in the results
    Examples:
      |batch|count|
      |foo|4|
      |bar|4|
      |nopackages|0|

  Scenario Outline: Filter by account
    Given 1 package under account/project "FDA-FDA"
    Given 1 package under account/project "FDA-PRB"
    Given 1 package under account/project "UF-UF"
    Given 1 package under account/project "UF-FHP"
    Given an account/project "FOO-BAR"
    Given I goto "/packages"
    When I select account "<account>"
    And I press "Set Scope"
    Then I should have <count> package in the results
    Examples:
      |account|count|
      |FDA|2|
      |UF|2|
      |FOO|0|

  Scenario Outline: Filter by project
    Given 1 package under account/project "FDA-FDA"
    Given 1 package under account/project "FDA-PRB"
    Given an account/project "FOO-BAR"
    Given I goto "/packages"
    When I select project "<project>"
    And I press "Set Scope"
    Then I should have <count> package in the results
    Examples:
      |project|count|
      |FDA-FDA|1|
      |PRB-FDA|1|
      |BAR-FOO|0|

  Scenario Outline: Filter by activity
    Given 1 rejected package
    And 1 archived package
    And 1 submitted package
    And 1 snafu package
    And 1 disseminated package
    And I goto "/packages"
    When I select activity "<activity>"
    And I press "Set Scope"
    Then I should have <count> package in the results
    Examples:
      |activity|count|
      |reject|1|
      |submit|1|
      |snafu|1|
      |archived|1|
      |disseminated|1|
      |withdrawn|0|

