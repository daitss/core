Feature: Cases where packages snafu in processing

  Scenario: A submission and attempted ingest of a known virus infected by an operator
    Given an archive operator
    And a workspace
    And the submission of a known virus infected package
    When ingest is attempted on that package
    Then the package is rejected
    And there is an operations event for the submission
    And there is an operations event for the reject
