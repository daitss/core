Feature: Manage accounts
  In order to alter accounts at runtime
  operator
  wants an interface to modify accounts

  Scenario: navigate to the accounts page
    Given I am on the home page
    When I follow "accounts"
    Then I should be on the accounts page
    And I should see "accounts" within ".breadcrumbs"

  Scenario: create a new account
    Given I am on the accounts page
    When I follow "add account"
    And I fill in "Id" with "PE"
    And I fill in "Description" with "Planet Express"
    And I press "Save Account"
    Then I should be on the PE account page
    Then I should see "account PE created" within ".notice"
    And I should see "Planet Express"
    And I should see "default project"

    @wip
  Scenario: view an account
    Given an account "PE"
    And account "PE" has a project "SNUX2"
    And account "PE" has a project "BEND"
    When I go to the PE account page
    Then I should see "PE"
    Then I should see "PE" within ".breadcrumbs"
    And I should see "SNUX2"
    And I should see "BEND"

  Scenario: modify an account
    Given an account "PE"
    And I am on the PE account page
    And I follow "edit account"
    When I fill in "Description" with "something else entirely"
    And I press "Update Account"
    Then I should see "account PE updated" within ".notice"
    And I should see "something else entirely"
