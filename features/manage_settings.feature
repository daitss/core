Feature: Manage settings
  In order to alter settings at runtime
  operator
  wants an interface to modify settings

  Scenario: Modify settings
    Given I am on the settings page
    When I fill in "Throttle" with "99"
    And I press "Save Settings"
    Then the "Throttle" field should contain "99"
    And I should see "Settings Updated" within ".notice"
