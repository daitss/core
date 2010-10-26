Feature: ingest a package

  Scenario: ingest a package. After complete, look for aip record, storage record, and events
    Given I submit "haskell-nums-pdf"
    When I click on "ingesting"
    And I choose "start"
    And I press "Update"
    And I should be redirected
    And I wait for it to finish
    Then I should be redirected
    And I should be at the package page
    And there should be an "ingest started" event
    And there should not be an "ingest snafu" event
    And there should be an "ingest finished" event

  Scenario: ingest a virus infected package. Package should snafu
    Given I submit "virus"
    When I click on "ingesting"
    And I choose "start"
    And I press "Update"
    Then I should be redirected
    And I wait for it to finish
    And I should not be redirected
    And it should be snafu because "virus detected"
