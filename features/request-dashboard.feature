Feature: Request Dashboard

  Scenario: should display requests by default
    Given an archived package
    When I goto its package page
    And I choose request type "disseminate"
    And I fill in "note" with "disseminate, please"
    And I press "Request"
    And I should be redirected
    And I goto "/requests"
    Then I should see a disseminate request for the package

  Scenario: should filter by type
    Given an archived package
    When I goto its package page
    And I choose request type "disseminate"
    And I fill in "note" with "disseminate, please"
    And I press "Request"
    And I should be redirected
    And I goto "/requests"
    And I select "disseminate" from "type-scope" filter
    And I press "Set Scope"
    Then I should see a disseminate request for the package

  Scenario: should filter by type
    Given an archived package
    When I goto its package page
    And I choose request type "disseminate"
    And I fill in "note" with "disseminate, please"
    And I press "Request"
    And I should be redirected
    And I goto "/requests"
    And I select "withdraw" from "type-scope" filter
    And I press "Set Scope"
    Then I should not see a disseminate request

  Scenario: should filter by batch
    Given an archived package
    When I goto its package page
    And I choose request type "disseminate"
    And I fill in "note" with "disseminate, please"
    And I press "Request"
    And I should be redirected
    And I goto "/packages"
    And I fill in "name" with "mybatch"
    And I press "Save as Batch"
    And I should be redirected
    And I goto "/requests"
    And I select "mybatch" from "batch-scope" filter
    And I press "Set Scope"
    Then I should see a disseminate request

  Scenario: should filter by batch
    Given an archived package
    And the following packages:
      |E00000000_000001|
    And batch "foo" with the following packages:
      |E00000000_000001|
    When I goto its package page
    And I choose request type "disseminate"
    And I fill in "note" with "disseminate, please"
    And I press "Request"
    And I should be redirected
    And I goto "/requests"
    And I select "foo" from "batch-scope" filter
    And I press "Set Scope"
    Then I should not see a disseminate request

  Scenario: should filter by account
    Given an archived package
    When I goto its package page
    And I choose request type "disseminate"
    And I fill in "note" with "disseminate, please"
    And I press "Request"
    And I should be redirected
    And I goto "/requests"
    And I select "SYSTEM" from "account-scope" filter
    And I press "Set Scope"
    Then I should not see a disseminate request

  Scenario: should filter by account
    Given an archived package
    When I goto its package page
    And I choose request type "disseminate"
    And I fill in "note" with "disseminate, please"
    And I press "Request"
    And I should be redirected
    And I goto "/requests"
    And I select "ACT" from "account-scope" filter
    And I press "Set Scope"
    Then I should see a disseminate request

  Scenario: should filter by project
    Given an archived package
    When I goto its package page
    And I choose request type "disseminate"
    And I fill in "note" with "disseminate, please"
    And I press "Request"
    And I should be redirected
    And I goto "/requests"
    And I select "PRJ-ACT" from "project-scope" filter
    And I press "Set Scope"
    Then I should see a disseminate request

  Scenario: should filter by project
    Given an archived package
    When I goto its package page
    And I choose request type "disseminate"
    And I fill in "note" with "disseminate, please"
    And I press "Request"
    And I should be redirected
    And I goto "/requests"
    And I select "default-ACT" from "project-scope" filter
    And I press "Set Scope"
    Then I should not see a disseminate request

  Scenario: should filter by user
    Given an archived package
    When I goto its package page
    And I choose request type "disseminate"
    And I fill in "note" with "disseminate, please"
    And I press "Request"
    And I should be redirected
    And I goto "/requests"
    And I select "operator" from "user-scope" filter
    And I press "Set Scope"
    Then I should see a disseminate request

  Scenario: should filter by user
    Given an archived package
    When I goto its package page
    And I choose request type "disseminate"
    And I fill in "note" with "disseminate, please"
    And I press "Request"
    And I should be redirected
    And I goto "/requests"
    And I select "affiliate" from "user-scope" filter
    And I press "Set Scope"
    Then I should not see a disseminate request

  Scenario: should filter by status
    Given an archived package
    When I goto its package page
    And I choose request type "disseminate"
    And I fill in "note" with "disseminate, please"
    And I press "Request"
    And I should be redirected
    And I goto "/requests"
    And I select "enqueued" from "status-scope" filter
    And I press "Set Scope"
    Then I should see a disseminate request

  Scenario: should filter by status
    Given an archived package
    When I goto its package page
    And I choose request type "disseminate"
    And I fill in "note" with "disseminate, please"
    And I press "Request"
    And I should be redirected
    And I goto its package page
    And I fill in "cancel_note" with "cancel, please"
    And I press "Cancel"
    And I should be redirected
    And I goto "/requests"
    And I select "enqueued" from "status-scope" filter
    And I press "Set Scope"
    Then I should not see a disseminate request
