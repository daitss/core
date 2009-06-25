Feature: Ingest
  Ingest should take a aip as argument and return certain error codes
  
  Scenario: completed ingest
    Given a good aip
    When I ingest
    Then it should print "ingested"
    And it should return status 0

  Scenario: non aip argument
    Given an non-existent aip
    When I ingest
    Then it should print "cannot process"
    And it should return status 1
    
  Scenario: rejected aip
    Given an invalid aip
    When I ingest
    Then it should print "rejected"
    And it should return status 2

  Scenario: snafu aip
    Given a good aip
    And a systemic problem
    When I ingest
    Then it should print "snafu"
    And it should return status 3
    