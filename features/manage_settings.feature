Feature: Manage settings
  In order to alter settings at runtime
  operator
  wants an interface to modify settings

  Scenario: navigate to the settings page
    Given I am on the home page
    When I follow "settings"
    Then I should be on the settings page
    And I should see "settings" within ".breadcrumbs"

  Scenario: Modify settings
    Given I am on the settings page
    When I fill in "Throttle" with "99"
    And I press "Save Settings"
    Then the "Throttle" field should contain "99"
    And I should see "settings updated" within ".notice"
