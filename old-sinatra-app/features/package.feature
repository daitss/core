Feature: overview of a package

  Scenario: page describing the package
    Given I submit a package
    When I goto its package page
    Then the response should be OK

  Scenario: show overview of the submission
    Given I submit a package
    When I goto its package page
    Then in the submission summary I should see the name
    And in the submission summary I should see the account
    And in the submission summary I should see the project

  Scenario: show the current job
    Given I submit a package
    When I goto its package page
    Then in the jobs summary I should see an ingest wip

  Scenario: show the current stashed location
    Given I submit a package
    And a stash bin named "default bin"
    And I stash it in "default bin"
    When I goto its package page
    Then in the jobs summary I should see a stashed ingest wip in "default bin"

  Scenario: show that no jobs are running
    Given an archived package
    When I goto its package page
    Then in the jobs summary I should see that no jobs are pending

  Scenario: show the operations events
    Given I submit a package
    When I goto its package page
    Then in the events I should see a "submit" event with "" in the notes

  Scenario: download ingest report
    Given an archived package
    When I goto its package page
    And I click on "ingest report download"
    Then the response should contain a valid ingest report

  Scenario: download ingest report for not yet archived package
    Given I submit a package
    When I goto its ingest report
    Then the response code should be 404

  Scenario: show the aip
    Given an archived package
    When I goto its package page
    Then in the aip section I should see a link to the descriptor
    Then in the aip section I should see copy url
    Then in the aip section I should see copy size
    Then in the aip section I should see copy sha1
    Then in the aip section I should see number of datafiles

  Scenario: access the descriptor
    Given an archived package
    And I goto its package page
    When I click on "mets descriptor"
    Then the body should be mets xml
