Feature: stashing a wip

  Scenario Outline: stash to a wip
    Given a workspace with 1 <pre status> wip
    And a stash bin named "default bin"
    And I goto its wip page
    When I choose "stash"
    And I select "default bin"
    And I press "Update"
    Then the response should be <page status>
    And I should be at <page> page
    Examples:
      | pre status | page status | page            |
      | idle       | OK          | the stashed wip |
      | running    | NG          | an error        |
