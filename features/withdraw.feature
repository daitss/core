Feature: withdraw a package

  Scenario: withdraw a package
    Given "haskell-nums-pdf" is archived
    When I choose request type "withdraw"
    And I press "Request"
    And I wait for the "withdraw" to finish
    And I goto its package page
    And there should be an "ingest started" event
    And there should be an "ingest finished" event
    And there should be an "withdraw started" event
    And there should be an "withdraw finished" event
