Feature: interactive submission

  Scenario: the submission form
    Given I goto "/submit"
    When I select a sip to upload
    And I press "Submit"
    Then I should be at a wip page
