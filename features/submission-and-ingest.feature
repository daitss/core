Feature: A submission and subsequent ingest operation of a known good package
  should result in a successful ingest. Likewise, a submission an ingest of a known bad 
  package should result in a reject.

  Scenario: A submission and ingest of a known good package by an operator
    Given an archive operator
    And a workspace
    And the submission of a known good package
    When ingest is run on that package
    Then the package is present in the aip store
    And there is an operations event for the submission
    And there is an operations event for the ingest

  Scenario: A submission and ingest of a known good package by a contact
    Given an archive contact
    And a workspace
    And the submission of a known good package
    When ingest is run on that package
    Then the package is present in the aip store
    And there is an operations event for the submission
    And there is an operations event for the ingest

  Scenario: A submission and attempted ingest of a known empty package by an operator
    Given an archive operator
    And a workspace
    And the submission of a known empty package
    When ingest is attempted on that package
    Then the package is rejected
    And there is an operations event for the submission
    And there is an operations event for the reject

  Scenario: A submission and attempted ingest of a known checksum mismatch package by an operator
    Given an archive operator
    And a workspace
    And the submission of a known checksum mismatch package
    When ingest is attempted on that package
    Then the package is rejected
    And there is an operations event for the submission
    And there is an operations event for the reject

