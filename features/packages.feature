Feature: be able to locate any package

  Scenario: search for a package by sip name
    Given I submit a package
    And I goto "/packages"
    When I enter the sip name into the box
    And I press "Search"
    Then I should see the package in the results

  Scenario: search for a package by package id
    Given I submit a package
    And I goto "/packages"
    When I enter the package id into the box
    And I press "Search"
    Then I should see the package in the results

  Scenario: search for multiple packages
    Given I submit 2 packages
    And I goto "/packages"
    When I enter the package ids into the box
    And I press "Search"
    Then I should see the packages in the results

  Scenario: search for multiple packages using sip and package ids
    Given I submit 2 packages
    And I goto "/packages"
    When I enter one package id and one sip id into the box
    And I press "Search"
    Then I should see the packages in the results

  Scenario: show the latest activity
    Given I submit 2 packages
    When I goto "/packages"
    Then I should see a "latest activity" heading
    And I should see the packages in the results
    And I should see the following columns:
      | intellectual entity id (ieid) | package | size (MB) | # of datafiles | account | activity | time |
    And the package column should link to a package

  Scenario: rejects should display in packages list
    Given I goto "/packages"
    When I select "bad-account" to upload
    And I press "Submit"
    And I should be redirected
    Then I should see the package in the results

  Scenario: snafus should display in packages list
    Given I submit "virus"
    When I click on "ingesting"
    And I choose "start"
    And I press "Update"
    And I should be redirected
    And I wait for it to finish
    And I goto "/packages"
    Then I should see the package in the results

  Scenario: snafus should display in snafu list
    Given I submit "virus"
    When I click on "ingesting"
    And I choose "start"
    And I press "Update"
    And I should be redirected
    And I wait for it to finish
    And I goto "/errors"
    Then I should see that package in the results

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
      | start_date | end_date  | count |
      | 3/15/2011  | 3/16/2011 | 4     |
      | 2/15/2011  | 2/16/2011 | 4     |
      | 3/15/2011  |           | 4     |
      | 2/15/2011  |           | 8     |
      |            | 3/17/2011 | 12    |
      |            |           | 12    |
      | 3/17/2011  |           | 0     |
      |            | 1/1/2011  | 0     |
      |            | 1/16/2011 | 4     |

  Scenario Outline: Filter by batch
    Given 4 packages under batch "foo"
    Given 4 packages under batch "bar"
    And a batch "nopackages"
    Given I goto "/packages"
    When I select batch "<batch>"
    And I press "Set Scope"
    Then I should have <count> package in the results
    Examples:
      | batch      | count |
      | foo        | 4     |
      | bar        | 4     |
      | nopackages | 0     |

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
      | account | count |
      | FDA     | 2     |
      | UF      | 2     |
      | FOO     | 0     |

  Scenario Outline: Filter by project
    Given 1 package under account/project "FDA-FDA"
    Given 1 package under account/project "FDA-PRB"
    Given an account/project "FOO-BAR"
    Given I goto "/packages"
    When I select project "<project>"
    And I press "Set Scope"
    Then I should have <count> package in the results
    Examples:
      | project | count |
      | FDA-FDA | 1     |
      | PRB-FDA | 1     |
      | BAR-FOO | 0     |

  Scenario: If conflicting account/project specified, empty result set should be returned
    Given 1 package under account/project "FDA-FDA"
    Given 1 package under account/project "FDA-PRB"
    Given 1 package under account/project "FOO-BAR"
    Given an account/project "FOO-BAR"
    Given I goto "/packages"
    When I select project "BAR-FOO"
    When I select account "FDA"
    And I press "Set Scope"
    Then I should have 0 package in the results

  Scenario Outline: Filter by activity
    Given 1 rejected package
    And 1 archived package
    And 1 submitted package
    And 1 snafu package
    And 1 disseminated package
    And I goto "/packages"
    When I select activity "<activity>"
    And I press "Set Scope"
    And I wait for "1.0" seconds
    Then I should have <count> package in the results
    Examples:
      | activity     | count |
      | rejected     | 1     |
      | submitted    | 1     |
      | error        | 1     |
      | archived     | 1     |
      | disseminated | 1     |
      | withdrawn    | 0     |

  Scenario: Show aggregates for result set
    Given 3 archived package
    When I goto "/packages"
    And I press "Set Scope"
    Then I should see "3 packages"
    And I should see "2.68 MB"
    And I should see "9 files"

  Scenario: legacy packages should show timestamp of last legacy op event
    Given 1 legacy package
    When I goto "/packages"
    When I search for the package
    And I press "Search"
    Then I should see the package in the results
    Then the latest activity should be "daitss v.1 provenance"
    And the timestamp should be "Sat Jan 01 2011 11:11:11 AM"
