Feature: overview of a package

  Scenario: page describing the package
    Given I submit a package
    When I goto its package page
    Then the response should be OK

  Scenario: show overview of the submission
    Given I submit a package
    When I goto its package page
    Then in the submission summary I should see the sip
    And in the submission summary I should see the account
    And in the submission summary I should see the project

  Scenario: show the current jobs
    Given I submit a package
    When I goto its package page
    Then in the jobs summary I should see an ingest wip

  Scenario: show the operations events
    Given I submit a package
    When I goto its package page
    Then in the events I should see a submission event

  Scenario: show the aip
