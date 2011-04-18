Feature: stashing a wip

  Scenario Outline: stash to a wip
    Given a <pre status> wip
    And a stash bin named "default bin"
    And I goto its wip page
    When I choose "stash"
    And I select "default bin"
    And I press "Update"
    Then I should <redir>
    And I should be at <page> page
    Examples:
      | pre status | redir              | page            |
      | idle       |  be redirected     | the stashed wip |
      | running    |  not be redirected | an error        |

  Scenario: stash to a wip
    Given a idle wip
    And a stash bin named "default bin"
    And I goto its wip page
    When I choose "stash"
    And I select "default bin"
    And I press "Update"
    And I goto its wip page
    And it should have an "stash" event by agent "operator"
 
  Scenario: stash to a wip
    Given a idle wip
    And a stash bin named "default bin"
    And I goto "/workspace"
    When I choose "stash"
    And I select "default bin"
    And I press "Update"
    And I goto its wip page
    And it should have an "stash" event by agent "operator"
 
