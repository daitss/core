Feature: Start submissions
  In order ingest submissions
  As an operator
  I want to start and stop ingests in the workspace

  Scenario: start all packages
    Given I submit a package
    Given I submit another package
    When I type "boss start all"
    And I type "boss list"
    Then they should be in the list
    
  Scenario: stop all packages
    Given I submit a package
    Given I submit another package
    When I type "boss start all"
    And I type "boss stop all"
    And I type "boss list"
    Then they should not be in the list

  Scenario: start a single package
    Given I submit a package
    Given I submit another package
    And aip-0 is one of them
    When I type "boss start aip-0"
    And I type "boss list"
    Then it should be in the list

  Scenario: stop a single package
    Given I submit a package
    Given I submit another package
    And aip-0 is one of them
    When I type "boss start aip-0"
    And I type "boss stop aip-0"
    And I type "boss list"
    Then it should not be in the list