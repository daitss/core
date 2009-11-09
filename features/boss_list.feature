Feature: Boss list
  In order view the current status of the workspace
  As an operator
  I want to list packages by attributes

  Scenario: list all packages
    
  Scenario Outline: list ingesting packages (all ingesting)
    Given I submit a package
    And I submit another package
    When I <action> "boss start <package>"
    And I type "boss list ingesting"
    Then <cardinality> <condition> be in the list
    And the list should have <count> aips
    
    Examples:
      | package | action          | count | cardinality | condition  |
      | all     | type            | 2     | they        | should     |
      | aip-0   | type            | 1     | it          | should     |
      | aip-0   | murmur | 0     | they        | should not |
    
    
  Scenario: list pending packages  
  Scenario: list stopped packages
  Scenario: list rejected packages
  Scenario: list snafu packages
