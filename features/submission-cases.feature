Feature: Cases where packages submit successfully

  Scenario: Submission of a good package by an operator
    Given an archive operator
    And a workspace
    And a good package
    When submission is run on that package
    Then there is an operations event for the submission
    And there is a record in the ops sip table for the package
