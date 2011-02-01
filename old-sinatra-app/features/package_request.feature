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
    And I fill in request note with "<note>"
    And I press "Request"
    Then I should be redirected
    And I should see a <type> request with note "<note>" and authorized "<authorized>"
    Examples:
      | type        | note      | authorized |
      | disseminate | nice job! | yes        |
      #      | withdraw    | good bye  | yes        |
      #| peek        | oh hai    | yes        |

  Scenario Outline: requests can be canceled
    Given an archived package
    And a <type> request
    When I goto its package page
    And I press "Cancel" for the request
    Then I should see a <type> request with status "cancelled"
    And there should be an "<type> request cancelled" event
    Examples:
      | type        |
      | disseminate |
      #| withdraw    |
      #| peek        |

  Scenario: duplicate requests result in 400 returned
    Given an archived package
    And a disseminate request
    When I goto its package page
    And I choose request type "disseminate"
    And I press "Request"
    Then the response code should be 400
 

  Scenario: the top request can has a wip
