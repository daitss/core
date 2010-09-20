Feature: stashing a wip

  Scenario Outline: stash to a wip
    Given a <pre status> wip
    And a stash bin named "default bin"
    And I goto its wip page
    When I choose "stash"
    And I select "default bin"
    And I press "Update"
    And I should be at <page> page
    Examples:
      | pre status |  page            |
      | idle       |  the stashed wip |
      | running    |  an error        |
