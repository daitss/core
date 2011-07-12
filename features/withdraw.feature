Feature: withdraw a package

  Scenario: withdraw a package by operator
    Given I am logged in as an "operator2"
    Given "haskell-nums-pdf" is archived
    And I goto its package page
    When I choose request type "withdraw"
    And I fill in "note" with "withdraw, please"
    And I press "Request"
    When I log out and log in as an "operator"
    And I goto its package page
    And I press "authorize"
    And I wait for the "withdraw" to finish
    And I goto its package page
    And I should not see "submit request"
    And there should be an "ingest started" event
    And there should be an "ingest finished" event
    And there should be an "withdraw started" event
    And there should be an "withdraw finished" event
    And there should be an "withdraw request authorized" event

  Scenario: attempt to self-authorize should result in 403
    Given "haskell-nums-pdf" is archived
    And I goto its package page
    When I choose request type "withdraw"
    And I fill in "note" with "withdraw, please"
    And I press "Request"
    And I goto its package page
    And I press "authorize"
    Then the response code should be 403
