Feature: list wips
  To manage the processing of information packages
  An operator should be able to to view wips in the workspace

  Scenario Outline:: listing
    Given an empty workspace
    And I submit <quantity> sips
    And I goto "/"
    When I click on "workspace"
    Then there should be <quantity> wip

    Examples:
      | quantity |
      |        0 |
      |        5 |
      |       10 |
      |       50 |
