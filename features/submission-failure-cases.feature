Feature: Cases where packages fail to submit

  Scenario: Attempted submission of a checksum mismatch package by an operator
    Given an archive operator
    And a workspace
    And the submission of a known checksum mismatch package
    When ingest is attempted on that package
    Then the package is rejected
    And there is an operations event for the submission
    And there is an operations event for the reject

  Scenario: Attemtped submission of an empty package by an operator
    Given an archive operator
    And a workspace
    And the submission of a known empty package
    When ingest is attempted on that package
    Then the package is rejected
    And there is an operations event for the submission
    And there is an operations event for the reject
