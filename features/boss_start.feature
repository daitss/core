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
    Given I submit a package
    When I type "boss start all"
    And I type "boss start aip-0"
    Then it should return status 2

  Scenario: start an ingesting package that does not exist
    When I type "boss start aip-0"
    Then it should return status 2
  
  Scenario: start a single package
    Given I submit a package
    Given I submit another package
    When I type "boss start aip-0"
    And I type "boss list ingesting"
    Then it should be in the list

  Scenario Outline: start a non-pending package
    Given I submit a package
    And it is tagged <tag>
    When I type "boss start aip-0"
    Then it should return status 2
    
    Examples:
      |tag|
      |REJECT|
      |SNAFU|
      |STOP|
    