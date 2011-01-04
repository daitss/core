Feature: update the processing of a wip

  Scenario Outline: updates to a wip
    Given a <pre status> wip
    And I goto its wip page
    When I choose "<task>"
    And I press "Update"
    Then the response should be <page status>
    And the package should be <post status>
    Examples:
      | pre status | task    | page status | post status |
      | idle       | start   | OK          | running     |
      | running    | start   | NG          | don't know  |
      | idle       | stop    | NG          | don't know  |
      | running    | stop    | OK          | stop        |
      | idle       | unsnafu | NG          | don't know  |
      | running    | unsnafu | NG          | don't know  |
      | snafu      | unsnafu | OK          | idle        |
      | stop       | start   | OK          | running     |
      | dead       | start   | OK          | running     |
