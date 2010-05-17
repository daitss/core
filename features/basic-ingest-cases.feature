Feature: A submission and subsequent ingest operation of a known good package
  should result in a successful ingest. Likewise, a submission an ingest of a known bad 
  package should result in a reject.

  Scenario: A submission and ingest of a known good package by an operator
    Given an archive operator
    And a workspace
    And a good package
    When submission is run on that package
    And ingest is run on that package
    Then the package is present in the aip store
    And there is an operations event for the submission
    And there is an operations event for the ingest

  Scenario: A submission and ingest of a known good package by a contact
    Given an archive contact
    And a workspace
    And a good package
    When submission is run on that package
    And ingest is run on that package
    Then the package is present in the aip store
    And there is an operations event for the submission
    And there is an operations event for the ingest

  Scenario: The submission and ingest of a package with a copy of itself inside itself
    Given an archive operator
    And a workspace
    And a package in package package
    When submission is run on that package
    And ingest is run on that package
    Then the package is present in the AIP store once
    And there is an operations event for the submission
    And there is an operations event for the ingest
