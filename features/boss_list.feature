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
      | package | action | count | cardinality | condition  |
      | all     | type   | 2     | they        | should     |
      | aip-0   | type   | 1     | it          | should     |
      | aip-0   | murmur | 0     | they        | should not |
    
    
  Scenario: list pending packages  
    Given I submit a package
    When I type "boss list pending"
    Then the list should have 1 aips
    And it should be in the list
    
  Scenario: list pending packages where none are pending
    Given I submit a package
    When I type "boss start all"
    And I type "boss list pending"
    Then the list should have 0 aips
    
  Scenario: list stopped packages
  Scenario: list rejected packages
  Scenario: list snafu packages
