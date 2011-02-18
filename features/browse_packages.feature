Feature: admin log
  In order to access package assets
  operators and affiliates
  want an interface to locate and view packages

  Background:
    Given an account "PE"
    Given account "PE" has a project "SNUX2"

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
    And I select "SNUX2" from "Project"
    And I press "Search"
    Then I should see "E0TESTING_KWH6T8"

  Scenario: search for a package in a date range
  Scenario: submit a package
