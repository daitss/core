Feature: snafu tab

  Scenario: snafu package should display in snafu tab
    Given a snafu package
    When I goto "/errors"
    Then I should see the package in the results
    And I should see the snafu error "oops this is not a real error!" in the results

  Scenario: snafu package should display in snafu tab even if subsequently stashed
    Given a snafu package
    And a stash bin named "default bin"
    And I goto "/workspace"
    When I choose "stash"
    And I select "default bin"
    And I press "Update"
    And I should be redirected
    And I goto "/errors"
    Then I should see the package in the results

  Scenario: snafu package that is subsequently re-ingested should not display in snafu tab
    Given a error package
    When I goto "/workspace"
    And I choose "reset"
    And I press "Update"
    And I should be redirected
    And I goto its package page
    And I click on "ingesting"
    And I choose "start"
    And I press "Update"
    Then I should be redirected
    And I wait for it to finish
    And I goto "/errors"
    Then I should not see the package in the results

  Scenario: previously ingested disseminate snafu should appear in list
    Given a previously ingested disseminate snafu package
    When I goto "/errors"
    Then I should see the package in the results

  Scenario: snafu package should display in snafu tab
    Given a snafu package
    Given a snafu package
    When I goto "/errors"
    And I fill in "name" with "default batch"
    And I press "Save as Batch"
    Then I should see 2 packages in batch "default batch"

  Scenario Outline: Filter by date
    Given 4 packages snafued on "3/16/2011"
    Given 4 packages snafued on "2/16/2011"
    Given 4 packages snafued on "1/16/2011"
    Given I goto "/errors"
    When I fill in "start_date" with "<start_date>"
    And I fill in "end_date" with "<end_date>"
    And I press "Set Scope"
    Then I should have <count> package in the results
    Examples:
      | start_date | end_date  | count |
      | 3/15/2011  | 3/16/2011 | 4     |
      | 2/15/2011  | 2/16/2011 | 4     |
      | 3/15/2011  |           | 4     |
      | 2/15/2011  |           | 8     |
      |            | 3/17/2011 | 12    |
      |            |           | 12    |
      | 3/17/2011  |           | 0     |
      |            | 1/1/2011  | 0     |
      |            | 1/16/2011 | 4     |

  Scenario Outline: Filter by batch
    Given 4 packages snafued under batch "foo"
    Given 4 packages snafued under batch "bar"
    And a batch "nopackages"
    Given I goto "/errors"
    When I select batch "<batch>"
    And I press "Set Scope"
    Then I should have <count> package in the results
    Examples:
      | batch      | count |
      | foo        | 4     |
      | bar        | 4     |
      | nopackages | 0     |

  Scenario Outline: Filter by account
    Given 1 package snafued under account/project "FDA-FDA"
    Given 1 package snafued under account/project "FDA-PRB"
    Given 1 package snafued under account/project "UF-UF"
    Given 1 package snafued under account/project "UF-FHP"
    Given an account/project "FOO-BAR"
    Given I goto "/errors"
    When I select account "<account>"
    And I press "Set Scope"
    Then I should have <count> package in the results
    Examples:
      | account | count |
      | FDA     | 2     |
      | UF      | 2     |
      | FOO     | 0     |

  Scenario Outline: Filter by project
    Given 1 package snafued under account/project "FDA-FDA"
    Given 1 package snafued under account/project "FDA-PRB"
    Given an account/project "FOO-BAR"
    Given I goto "/errors"
    When I select project "<project>"
    And I press "Set Scope"
    Then I should have <count> package in the results
    Examples:
      | project | count |
      | FDA-FDA | 1     |
      | PRB-FDA | 1     |
      | BAR-FOO | 0     |

  Scenario: If conflicting account/project specified, empty result set should be returned
    Given 1 package snafued under account/project "FDA-FDA"
    Given 1 package snafued under account/project "FDA-PRB"
    Given 1 package snafued under account/project "FOO-BAR"
    Given an account/project "FOO-BAR"
    Given I goto "/errors"
    When I select project "BAR-FOO"
    When I select account "FDA"
    And I press "Set Scope"
    Then I should have 0 package in the results

  Scenario Outline: Filter by snafu activity
    Given a snafu package
    And a stashed snafu package
    And a unsnafued snafu package
    And I goto "/errors"
    When I select activity "<status>"
    And I press "Set Scope"
    Then I should have <count> package in the results
    Examples:
      | status    | count |
      | error     | 1     |
      | reset     | 1     |
      | stashed   | 1     |

  Scenario: Filter by error message
    Given a snafu package
    Given a different snafu package
    And I goto "/errors"
    When I fill in "error-message" with "oops this is not a real error!"
    And I press "Set Scope"
    Then I should have 1 package in the results

