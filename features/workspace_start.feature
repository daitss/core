Feature: start all
  To start all non-running wips

  Scenario: one non-running sip
    Given an empty workspace
    And I submit a sip
    And I goto "/"
    And I click on "workspace"
    When I choose "start all"
    And I press "Update"
    Then there should be 1 running sip
