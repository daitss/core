Feature: browse packages
  In order to access package assets
  operators and affiliates
  want an interface to locate and view packages

  Background:
    Given an account "PE"
    Given account "PE" has a project "SNUX2"
    Given project "PE/SNUX2" has 100 arbitrary packages

  Scenario: navigate to packages index
    Given I am on the home page
    When I follow "packages"
    Then I should be on the packages page
    And I should see "packages" within ".breadcrumbs"

  Scenario: see a summary of holdings
    When I am on the packages page
    Then I should see "packages" within ".holdings"
    Then I should see "files" within ".holdings"
    Then I should see "storage" within ".holdings"

  Scenario: search for a package by id
    Given a package "E0TESTING_KWH6T8" in "PE/SNUX2"
    And I am on the packages page
    When I fill in "q" with "E0TESTING_KWH6T8"
    And I press "Search"
    Then I should see "E0TESTING_KWH6T8"

  Scenario: search for a package in a project
    Given a package "E0TESTING_KWH6T8" in "PE/SNUX2"
    And package "E0TESTING_KWH6T8" is "archived" at "2011-01-01T9:00"
    And I am on the packages page
    When I select "SNUX2" from "Project"
    And I press "Filter"
    Then I should see "E0TESTING_KWH6T8"

  Scenario: search for a package in by state
    Given the packages in "PE/SNUX2":
      | id               | status   | time            |
      | E0TESTING_XXXXXX | archived | 2011-01-01T9:00 |
      | E0TESTING_YYYYYY | rejected | 2011-01-01T9:00 |
    And I am on the packages page
    When I select "SNUX2" from "Project"
    And I select "2011" from "start_date_year"
    And I select "January" from "start_date_month"
    And I select "1" from "start_date_day"
    And I select "2011" from "end_date_year"
    And I select "January" from "end_date_month"
    And I select "1" from "end_date_day"
    And I select "archived" from "Status"
    And I press "Filter"
    Then I should see "E0TESTING_XXXXXX"
    And I should not see "E0TESTING_YYYYYY"

  Scenario: search for a package in by date range
    Given the packages in "PE/SNUX2":
      | id               | status   | time            |
      | E0TESTING_XXXXXX | archived | 2011-01-01T9:00 |
      | E0TESTING_YYYYYY | rejected | 2011-02-01T9:00 |
    And I am on the packages page
    When I select "SNUX2" from "Project"
    When I select "2011" from "start_date_year"
    When I select "January" from "start_date_month"
    When I select "1" from "start_date_day"
    When I select "2011" from "end_date_year"
    When I select "January" from "end_date_month"
    When I select "1" from "end_date_day"
    When I select "any" from "Status"
    And I press "Filter"
    Then I should see "E0TESTING_XXXXXX"
    And I should not see "E0TESTING_YYYYYY"

  Scenario: save a result set to a list
  Scenario: append a result set to a list
  Scenario: display a large result set on multiple pages
