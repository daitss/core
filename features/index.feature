Feature: index links
  To navigate to all resources

  Scenario: navigate to workspace
    Given I goto "/"
    When I click on "workspace"
    Then the response should be OK

  Scenario: navigate to workspace
    Given I goto "/"
    When I click on "submit"
    Then the response should be OK
