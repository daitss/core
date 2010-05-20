Feature: index links
  To navigate to all resources

  Scenario Outline: navigate to places
    Given I goto "/"
    When I click on "<link>"
    Then the response should be OK
    Examples:
      | link       |
      | workspace  |
      | submit     |
      | packages   |
      | stashspace |
