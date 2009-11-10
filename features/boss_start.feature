Feature: Boss start
  In order ingest packages
  As an operator
  I want to start multiple ingests

  Scenario: start all packages
    Given I submit a package
    Given I submit another package
    When I type "boss start all"
    And I type "boss list ingesting"
    Then they should be in the list
    
  Scenario: start an ingesting package
  
  Scenario: start a single package
    Given I submit a package
    Given I submit another package
    And aip-0 is one of them
    When I type "boss start aip-0"
    And I type "boss list ingesting"
    Then it should be in the list

  Scenario: start a non-pending package