Feature: disseminate a package

  Scenario: disseminate a package
    Given "haskell-nums-pdf" is archived
    When I choose request type "disseminate"
    And I press "Request"
    And I wait for the "disseminate" to finish
    And I goto its package page
    Then there should be link to a dip
    And there should be an "ingest started" event
    And there should be an "ingest finished" event
    And there should be an "disseminate started" event
    And there should be an "disseminate finished" event
    And there should be an "disseminate finished" event
    And clicking the dip link downloads the tarball
