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
    Given I submit 2 sips
    And I goto "/packages"
    When I enter the package ids into the box
    And I press "Search"
    Then I should see the packages in the results

  Scenario: search for multiple packages using sip and package ids
    Given I submit 2 sips
    And I goto "/packages"
    When I enter one package id and one sip id into the box
    And I press "Search"
    Then I should see the packages in the results
