Feature: Boss list
  In order view the current status of the workspace
  As an operator
  I want to list packages by attributes

  Scenario: list all packages
    
  Scenario: list ingesting packages (all ingesting)
    Given I submit a package
    And I submit another package
    When I type "boss start all"
    And I type "boss list ingesting"
    Then they should be in the list
    And the list should have 2 aips
    
  Scenario: list ingesting packages (some ingesting)
    Given I submit a package
    And I submit another package
    When I type "boss start aip-0"
    And I type "boss list ingesting"
    Then it should be in the list
    And the list should have 1 aip

  Scenario: list ingesting packages (none ingesting)
    Given I submit a package
    And I submit another package
    When I type "boss list ingesting"
    Then they should not be in the list
    And the list should have 0 aips
    
  Scenario: list pending packages  
  Scenario: list stopped packages
  Scenario: list rejected packages
  Scenario: list snafu packages