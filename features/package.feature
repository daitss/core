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

  Scenario: show the legacy events
    Given I submit a package with some legacy events
    When I goto its package page
    Then in the events I should see a "legacy operations data" event with "" in the notes

  Scenario: don't show the legacy events if there aren't any
    Given I submit a package
    When I goto its package page
    Then I should not see "legacy operations data"

  Scenario: hide the fixity events by default
    Given I submit a package with some fixity events
    When I goto its package page
    Then in the events I should not see a "fixity failure" event
    And in the events I should not see a "fixity success" event

  Scenario: show the fixity events
    Given I submit a package with some fixity events
    When I goto its package page
    And I click on "show fixity events"
    Then in the events I should see a "fixity success" event with "" in the notes

  Scenario: download ingest report
    Given an archived package
    When I goto its package page
    And I click on "ingest report"
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
    Then in the aip section I should see aip size
    Then in the aip section I should see copy sha1
    Then in the aip section I should see number of datafiles

  Scenario: access the descriptor
    Given an archived package
    And I goto its package page
    When I click on "mets descriptor"
    Then the body should be mets xml

  Scenario: should be able to comment on an event
    Given an archived package
    When I goto its package page
    When I click on "0 comment(s)"
    And I fill in "comment_text" with "foo"
    And I press "Submit"
    And I should be redirected
    Then I should see a comment with "foo" by operator

  Scenario: should see an accurate count of comments with events
    Given an archived package
    When I goto its package page
    When I click on "0 comment(s)"
    And I fill in "comment_text" with "foo"
    And I press "Submit"
    And I goto its package page
    Then I click on "1 comment(s)"
    Then I should see a comment with "foo" by operator
