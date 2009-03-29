Feature: Submission
  In order to for an AIP to be ingested
  There must be a sip to start with

  Scenario: Submit a valid tarball sip
    Given a sip tarball
    When I submit it
    Then it should be accessable as an aip
    And no errors should be reported

  Scenario: Submit an invalid tarball sip
    Given a random string of bytes
    When I submit it
    Then it should be not accepted by the system
    And errors should be reported
