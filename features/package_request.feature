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
    And there should be an "<type> request placed" event
    Examples:
      | type        | note      | authorized |
      | disseminate | nice job! | yes        |
      | withdraw    | good bye  | no         |

  Scenario: requests can be canceled
    Given an archived package
    And a disseminate request
    When I goto its package page
    And I fill in cancel note with "cancelling request"
    And I press "Cancel"
    Then I should see a disseminate request with status "cancelled"
    And there should be an "disseminate request cancelled" event
    And the "disseminate request cancelled" event should have note "cancelling request"

  Scenario: 400 if trying to cancel a request after it has been picked up
    Given an archived package
    And a disseminate request
    When I goto its package page
    And I fill in cancel note with "cancelling request"
    And the request is picked up by pulse and sent to workspace
    And I press "Cancel"
    Then the response code should be 400

  Scenario: creating request without a note results in 400
    Given an archived package
    When I goto its package page
    And I choose request type "disseminate"
    And I press "Request"
    Then the response code should be 400

  Scenario: cancelling request without a note results in 400
    Given an archived package
    And a disseminate request
    When I goto its package page
    And I press "Cancel"
    Then the response code should be 400

  Scenario: duplicate requests result in 400 returned
    Given an archived package
    And a disseminate request
    When I goto its package page
    And I choose request type "disseminate"
    And I press "Request"
    Then the response code should be 400
 
