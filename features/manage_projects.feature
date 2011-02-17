Feature: Manage projects
  In order to alter projects at runtime
  operator
  wants an interface to modify projects

  Background:
    Given an account "PE"

  Scenario: create a new project
    Given I am on the PE account page
    When I fill in "Id" with "SNUX2"
    And I fill in "Description" with "snu snu"
    And I press "Add Project"
    Then I should see "SNUX2"
    And I should see "project SNUX2 created for PE" within ".notice"

  Scenario: navigate to a project
    Given account "PE" has a project "SNUX2"
    And I am on the PE account page
    When I follow "SNUX2"
    Then I should be on the account PE's SNUX2 project page
    And I should see "PE" within ".breadcrumbs"
    And I should see "SNUX2" within ".breadcrumbs"

  Scenario: modify a project
    Given account "PE" has a project "SNUX2"
    Given I am on the account PE's SNUX2 project page
    When I follow "modify project"
    And I fill in "Description" with "snu snu"
    And I press "Update Project"
    Then I should be on the account PE's SNUX2 project page
    And I should see "project SNUX2 updated for PE" within ".notice"

