Feature: package requests

  Scenario: no requrests just show the form
    Given an archived package
    When I goto its package page
    Then there should be a request heading
    And there should be a request form
    And there should not be a request table

  Scenario Outline: requests can be created
    Given an archived package
    When I goto its package page
    And I choose request type "<type>"
    And I press "Request"
    Then I should see a <type> request
    Examples:
      | type        |
      | disseminate |
      | withdraw    |
      | peek        |

  Scenario Outline: requests can be canceled
    Given an archived package
    And a <type> request
    When I goto its package page
    And I press "Cancel" for the request
    Then I should not see the request
    Examples:
      | type        |
      | disseminate |
      | withdraw    |
      | peek        |

  Scenario: the top request can has a wip
