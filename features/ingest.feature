Feature: Ingest
  Ingest should take a aip as argument and return certain error codes
  
  Scenario: completed ingest
    Given I submit a package
    When I ingest
    Then it should print "ingested"
    And it should return status 0

  Scenario: non aip argument
    Given an non-existent aip
    When I ingest
    Then it should print "cannot process"
    And it should return status 1
    
  Scenario: rejected aip
    Given I submit a package
    And it is invalid
    When I ingest
    Then it should print "rejected"
    And it should return status 2

  Scenario: snafu aip
    Given I submit a package
    And there is a systemic problem
    When I ingest
    Then it should print "snafu"
    And it should return status 3
    