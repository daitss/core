Feature: Validation
  In order to for an AIP to be ingested
  There must be no validation errors

  Scenario: Ingest a package that passes validation
    Given a valid AIP
    When it is ingested
    Then it should not be rejected
    And a validation event should exist

  Scenario: Reject a package that fails validation
    Given an invalid AIP
    When it is ingested
    Then it should be rejected
    And a validation event should not exist

