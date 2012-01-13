Feature: permissions

  Scenario Outline: Access to pages
    Given I am logged in as an "<role>"
    When I goto "<page>"
    Then the response code should be <response>

  Examples:
      | role      | page            | response |
      | operator  | /log            | 200      |
      | operator  | /profile        | 200      |
      | operator  | /errors         | 200      |
      | operator  | /workspace      | 200      |
      | operator  | /stashspace     | 200      |
      | operator  | /admin/accounts | 200      |
      | operator  | /batches        | 200      |
      | operator  | /requests       | 200      |
      | affiliate | /log            | 403      |
      | affiliate | /profile        | 403      |
      | affiliate | /errors         | 403      |
      | affiliate | /workspace      | 403      |
      | affiliate | /stashspace     | 403      |
      | affiliate | /admin          | 403      |
      | affiliate | /batches        | 403      |
      | affiliate | /requests       | 403      |

  Scenario: affiliate should not have access to batch form
    Given I am logged in as an "affiliate"
    When I goto "/packages"
    Then I should not see "Save as Batch"

  Scenario: operator should have access to batch form
    Given I am logged in as an "operator"
    When I goto "/packages"
    Then I should see "Save as Batch"

  Scenario: affiliate should not have access to request form
    Given I am logged in as an "affiliate"
    Given an archived package
    When I goto its package page
    Then I should not see "submit request"

  Scenario: operator should have access to request form
    Given I am logged in as an "operator"
    Given an archived package
    When I goto its package page
    Then I should see "submit request"

  Scenario: Access to aip details
    Given I am logged in as an "affiliate"
    Given an archived package
    When I goto its package page
    Then I should not see "copy url"
    Then I should not see "copy sha1"
    Then I should not see "copy md5"
    Then I should not see "aip descriptor"

  Scenario: filtering access
    Given I am logged in as an "affiliate"
    Given 1 package under account/project "ACT-FDA"
    Given 1 package under account/project "ACT-PRB"
    Given 1 package under account/project "FOO-BAR"
    Given I goto "/packages"
    When I press "Set Scope"
    Then I should have 2 package in the results

  Scenario: affiliates should only see own packages in recent activity
    Given I am logged in as an "affiliate"
    Given 1 package under account/project "ACT-FDA"
    Given 1 package under account/project "ACT-PRB"
    Given 1 package under account/project "FOO-BAR"
    Given I goto "/packages"
    Then I should have 2 package in the results

  Scenario: affiliate should not see anything batch related
    Given I am logged in as an "affiliate"
    Given an archived package
    When I goto "/packages"
    Then I should not see "batch"
    Then I should not see "Batch"

    # 1/13/2012: DIP links enabled for affilates
  Scenario: affiliate should not see DIP links
    Given this test in pending
    Given "haskell-nums-pdf" is archived
    When I choose request type "disseminate"
    And I fill in "note" with "disseminate, please"
    And I press "Request"
    And I wait for the "disseminate" to finish
    Given I am logged in as an "affiliate"
    When I goto its package page
    Then I should not see "dips"

  # 12/21/11: limiting results for affiliates has been disabled, so this test is disabled as well
  Scenario: affiliate should see limited resultset
    Given this test is pending 
    Given I am logged in as an "affiliate"
    Given 501 package under account/project "ACT-FDA"
    When I goto "/packages"
    When I press "Set Scope"
    Then I should have 500 package in the results

  Scenario: operator should see full resultset
    Given I am logged in as an "operator"
    Given 501 package under account/project "ACT-FDA"
    When I goto "/packages"
    When I press "Set Scope"
    Then I should have 501 package in the results
