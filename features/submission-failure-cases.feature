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

  Scenario: Attempted submission of a package where the project is invalid by an operator
    Given an archive operator
    And a workspace
    And a bad project package
    When submission is attempted on that package
    Then submission fails
    And there is an operations event for the submission

  Scenario: Attempted submission of a package where the account is invalid by an operator
    Given an archive operator
    And a workspace
    And a bad account package
    When submission is attempted on that package
    Then submission fails
    And there is an operations event for the submission

  Scenario: Attempted submission of a good package by an invalid user
    Given an archive invalid user
    And a workspace
    And a good package
    When submission is attempted on that package
    Then submission fails

  Scenario: Attempted submission of a descriptor not well formed package by operator
    Given an archive operator
    And a workspace
    And a descriptor not well formed package
    When submission is attempted on that package
    Then submission fails
    And there is an operations event for the submission

  Scenario: Attempted submission of a descriptor invalid package by operator
    Given an archive operator
    And a workspace
    And a descriptor invalid package
    When submission is attempted on that package
    Then submission fails
    And there is an operations event for the submission

  Scenario: Attempted submission of a descriptor missing package by operator
    Given an archive operator
    And a workspace
    And a descriptor missing package
    When submission is attempted on that package
    Then submission fails
    And there is an operations event for the submission

  Scenario: Attempted submission of good package by user without permission to submit
    Given an archive unauthorized contact
    And a workspace
    And a good package
    When submission is attempted on that package
    Then submission fails
