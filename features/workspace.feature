Feature: list wips
  To manage the processing of information packages
  An operator should be able to to view wips in the workspace

  Scenario: an empty workspace
    Given an empty workspace
    And I goto the operations interface
    When I click on "workspace"
    Then there should be 0 wips

  Scenario: a workspace with 1 wip
    Given an empty workspace
    And I submit a sip
    And I goto the operations interface
    When I click on "workspace"
    Then there should be 1 wip
