Feature: list wips
  To manage the processing of information packages
  An operator should be able to to view wips in the workspace

  Scenario: listing with states
    Given a workspace with the following wips:
      | count |   state |
      |     1 |    idle |
      |     1 | running |
      |     1 |   snafu |
      |     1 | stopped |
    When I goto "/workspace"
    Then there should be the following wips:
      | count |   state |
      |     1 |    idle |
      |     1 | running |
      |     1 |   snafu |
      |     1 | stopped |

  Scenario Outline: listing
    Given a workspace with <quantity> wips
    When I goto "/workspace"
    Then there should be <quantity> wips

    Examples:
      | quantity |
      |        0 |
      |        5 |
      #|       10 |
      #|       50 |
