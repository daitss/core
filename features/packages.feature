Feature: be able to locate any package

  Scenario: search for a package by sip name
    Given I submit a package
    And I goto "/packages"
    When I enter the sip name into the box
    And I press "Search"
    Then I should see the package in the results

  Scenario: search for a package by package id
    Given I submit a package
    And I goto "/packages"
    When I enter the package id into the box
    And I press "Search"
    Then I should see the package in the results

  Scenario: search for multiple packages
    Given I submit 2 packages
    And I goto "/packages"
    When I enter the package ids into the box
    And I press "Search"
    Then I should see the packages in the results

  Scenario: search for multiple packages using sip and package ids
    Given I submit 2 packages
    And I goto "/packages"
    When I enter one package id and one sip id into the box
    And I press "Search"
    Then I should see the packages in the results

  Scenario: show the latest activity
    Given I submit 2 packages
    When I goto "/packages"
    Then I should see a "latest activity" heading
    And I should see the packages in the results
    And I should see the following columns:
      | package | sip | size (MB) | # of datafiles | account | activity | time |
    And the package column should link to a package
     
  Scenario: rejects should display in packages list
    Given I goto "/packages"
    When I select "bad-account" to upload
    And I press "Submit"
    And I should be redirected
    Then I should see the package in the results

  Scenario: rejects should display in rejects list
    Given I goto "/packages"
    When I select "bad-account" to upload
    And I press "Submit"
    And I should be redirected
    And I goto "/rejects"
    Then I should see that package in the results

  Scenario: snafus should display in packages list
    Given I submit "virus"
    When I click on "ingesting"
    And I choose "start"
    And I press "Update"
    And I should be redirected
    And I wait for it to finish
    And I goto "/packages"
    Then I should see the package in the results

  Scenario: snafus should display in snafu list
    Given I submit "virus"
    When I click on "ingesting"
    And I choose "start"
    And I press "Update"
    And I should be redirected
    And I wait for it to finish
    And I goto "/snafus"
    Then I should see that package in the results
