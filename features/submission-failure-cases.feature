Feature: Cases where packages fail to submit

  Scenario: Attempted submission of a checksum mismatch package by an operator
    Given an archive operator
    And a workspace
    And a checksum mismatch package
    When submission is attempted on that package
    Then submission fails
    And there is an operations event for the submission

  Scenario: Attemtped submission of an empty package by an operator
    Given an archive operator
    And a workspace
    And an empty package
    When submission is attempted on that package
    Then submission fails
    And there is an operations event for the submission
