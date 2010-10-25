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
      | package | name | size (MB) | # of datafiles | account | activity | time |
    And the package column should link to a package
