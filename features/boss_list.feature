Feature: Boss list
  In order view the current status of the workspace
  As an operator
  I want to list packages by attributes

  Scenario: list all packages with status
    Given the following packages with states:
      | package | state     |
      | aip-0   | pending   |
      | aip-1   | ingesting |
      | aip-2   | REJECT    |
      | aip-3   | SNAFU     |
      | aip-4   | STOP      |
    When I type "boss list all"
    Then I should see the packages with the expected states
        
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
    Given I submit a package
    When I type "boss start all"
    And I type "boss stop all"
    And I type "boss list stopped"
    Then the list should have 1 aip
    
  Scenario: list stopped packages where none are stopped
    Given I submit a package
    When I type "boss start all"
    And I type "boss list stopped"
    Then the list should have 0 aips

  Scenario: list rejected packages
    Given I submit a package
    And it is tagged REJECT
    And I type "boss list rejected"
    Then the list should have 1 aip
  
  Scenario: list rejected packages where none are rejected
    Given I submit a package
    And I type "boss list rejected"
    Then the list should have 0 aips
  
  Scenario: list snafu packages
    Given I submit a package
    And it is tagged SNAFU
    And I type "boss list snafu"
    Then the list should have 1 aip
    
  Scenario: list snafued packages where none are snafu
    Given I submit a package
    And I type "boss list snafu"
    Then the list should have 0 aips    
