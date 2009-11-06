Feature: Boss list
  In order view the current status of the workspace
  As an operator
  I want to list packages by attributes

  Scenario: list all packages
    Given I submit a package
    Given I submit another package
    When I type "boss start all"
    And I type "boss list"
    Then they should be in the list
    
  Scenario: list ingesting packages
  Scenario: list pending packages
  Scenario: list stopped packages
  Scenario: list rejected packages
  Scenario: list snafu packages