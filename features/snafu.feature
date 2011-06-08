Feature: snafu tab

  Scenario: snafu package should display in snafu tab
    Given a snafu package
    When I goto "/snafus"
    Then I should see the package in the results
    And I should see the snafu error "oops this is not a real error!" in the results

  Scenario: snafu package should display in snafu tab even if subsequently stashed
    Given a snafu package
    And a stash bin named "default bin"
    And I goto "/workspace"
    When I choose "stash"
    And I select "default bin"
    And I press "update"
    And I should be redirected
    And I goto "/snafus"
    Then I should see the package in the results

  Scenario: snafu package that is subsequently re-ingested should not display in snafu tab
    Given a snafu package
    When I goto "/workspace"
    And I choose "unsnafu"
    And I press "Update"
    And I should be redirected
    And I goto its package page
    And I click on "ingesting"
    And I choose "start"
    And I press "update"
    Then I should be redirected
    And I wait for it to finish
    And I goto "/snafus"
    Then I should not see the package in the results

  Scenario: previously ingested disseminate snafu should appear in list
    Given a previously ingested disseminate snafu package
    When I goto "/snafus"
    Then I should see the package in the results
