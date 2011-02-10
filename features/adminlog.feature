Feature: admin log
  In order to track changes to administrative data
  operators
  want an interface to view the admin log data

  Scenario: view the log page
    Given an admin log entry "something happened"
    When I go to the adminlogs page
    Then I should see "something happened" within ".message"
    And I should see "by root" within ".agent"
    And I should see "less than a minute ago" within ".time"

  Scenario: add an admin log entry
    Given I am on the adminlogs page
    When I fill in "adminlog_message" with "something ad-hoc"
    And I press "Save Entry"
    Then I should see "something ad-hoc" within ".message"
    And I should see "by root" within ".agent"
    And I should see "less than a minute ago" within ".time"
    And I should see "admin log entry added" within ".notice"

  Scenario: view an admin log entry
    Given I am on the adminlogs page
    And an admin log entry "oh no, better check this out"
    When I follow "oh no, better check this out"
    Then I should see "oh no, better check this out" within ".message pre"
    And I should see "root" within ".agent a"
    And I should see "T" within ".time"
    # TODO the time checking could be better
