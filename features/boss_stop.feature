Feature: Boss stop
  In order stop an ingest
  As an operator
  I want to stop ingests
    
  Scenario: stop all packages
    Given I submit a package
    And I submit another package
    When I type "boss start all"
    And I type "boss stop all"
    And I type "boss list ingesting"
    Then they should not be in the list

  Scenario: stop a single package
    Given I submit a package
    Given I submit another package
    When I type "boss start aip-0"
    And I type "boss stop aip-0"
    And I type "boss list ingesting"
    Then it should not be in the list
    
  Scenario: stop a non-ingesting package
    Given I submit a package
    When I type "boss stop aip-0"
    Then it should return status 2
