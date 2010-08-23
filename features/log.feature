Feature: keep provenance of archive-level changes

  Scenario: add a log
    Given I goto "/log"
    When I enter a log message "foo bar baz"
    And I press "Update"
    Then I should see a log message "foo bar baz"
