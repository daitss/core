Feature: ingest a package

  Scenario Outline: ingest a package successfully
    Given I submit "<sip>"
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
    Examples:
      | sip              |
      | uri-escaped-href |
      | haskell-nums-pdf |

  Scenario: ingest a virus infected package. Package should snafu
    Given I submit "virus"
    When I click on "ingesting"
    And I choose "start"
    And I press "Update"
    Then I should be redirected
    And I wait for it to finish
    And I should not be redirected
    And it should be snafu because "virus detected"
