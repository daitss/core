Feature: ingest a package

  Scenario: ingest a package. After complete, look for aip record, storage record, and events
    Given I goto "/submit"
    When I select "haskell-nums-pdf" to upload
    And I press "Submit"
    And I click on "ingesting"
    And I choose "start"
    And I press "Update"
    When I wait for it to finish
    Then I should be at the package page
    And there should not be an "ingest snafu" event
    And there should be an "ingest finished" event

  Scenario: ingest a virus infected package. Package should snafu
    Given I goto "/submit"
    When I select "virus" to upload
    And I press "Submit"
    And I click on "ingesting"
    And I choose "start"
    And I press "Update"
    And I wait for it to finish
    Then it should be snafu because "virus detected"
