Feature: Start submissions
  In order ingest submissions
  As an operator
  I want to start and stop ingests in the workspace

  Scenario: start all packages
    Given a workspace with many aips
    When I type boss start for all packages
    And I type boss list
    Then they should show up in the list
    
  Scenario: stop all packages
    Given a workspace with many aips
    When I type boss start for all packages
    And I type boss stop for all packages
    And I type boss list
    Then they should not show up in the list

  Scenario: start a single package
    Given a workspace with many aips
    When I type boss start for a single package
    And I type boss list
    Then it should show up in the list

  Scenario: stop a single package
    Given a workspace with many aips
    When I type boss start for a single package
    And I type boss stop for that single package
    And I type boss list
    Then it should not show up in the list